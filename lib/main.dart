import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

// 智收网 · 安卓壳 App —— 全屏加载 www.fphsjypt.com。
// 网页更新 = App 自动同步(视频/动态/群组/以后任何新功能),永不重打包。
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ZswApp());
}

class ZswApp extends StatelessWidget {
  const ZswApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '智收网',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, primaryColor: const Color(0xFFD97757)),
      home: const WebShell(),
    );
  }
}

class WebShell extends StatefulWidget {
  const WebShell({super.key});
  @override
  State<WebShell> createState() => _WebShellState();
}

class _WebShellState extends State<WebShell> {
  InAppWebViewController? _controller;
  bool _loading = true;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final c = _controller;
        if (c != null && await c.canGoBack()) {
          c.goBack();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Stack(
            children: [
              InAppWebView(
                initialUrlRequest: URLRequest(url: WebUri('https://www.fphsjypt.com')),
                initialSettings: InAppWebViewSettings(
                  javaScriptEnabled: true,
                  domStorageEnabled: true,          // localStorage → 登录态保持
                  mediaPlaybackRequiresUserGesture: false,
                  allowsInlineMediaPlayback: true,
                  useOnDownloadStart: true,
                  geolocationEnabled: true,         // 发位置
                  supportZoom: false,
                  transparentBackground: false,
                ),
                onWebViewCreated: (c) => _controller = c,
                onLoadStop: (c, url) {
                  if (mounted) setState(() => _loading = false);
                },
                onReceivedError: (c, req, err) {
                  if (mounted) setState(() => _loading = false);
                },
                // 相机/相册/麦克风(发货源图、视频上传)一律授予
                onPermissionRequest: (c, request) async {
                  return PermissionResponse(
                    resources: request.resources,
                    action: PermissionResponseAction.GRANT,
                  );
                },
                onGeolocationPermissionsShowPrompt: (c, origin) async {
                  return GeolocationPermissionShowPromptResponse(
                    origin: origin, allow: true, retain: true);
                },
                // ↓ WebView 默认不处理网页 alert/confirm/prompt(会直接返回 false)。
                //   这里接成原生弹窗,网页里的报价确认/删除/举报/注销等才不会静默失效。
                onJsAlert: (c, req) async {
                  await showDialog(context: context, builder: (ctx) => AlertDialog(
                    content: Text(req.message ?? ''),
                    actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('确定'))]));
                  return JsAlertResponse(handledByClient: true);
                },
                onJsConfirm: (c, req) async {
                  final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
                    content: Text(req.message ?? ''),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('确定')),
                    ])) ?? false;
                  return JsConfirmResponse(handledByClient: true,
                    action: ok ? JsConfirmResponseAction.CONFIRM : JsConfirmResponseAction.CANCEL);
                },
                onJsPrompt: (c, req) async {
                  final tc = TextEditingController(text: req.defaultValue ?? '');
                  final v = await showDialog<String?>(context: context, builder: (ctx) => AlertDialog(
                    content: TextField(controller: tc, autofocus: true),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('取消')),
                      TextButton(onPressed: () => Navigator.pop(ctx, tc.text), child: const Text('确定')),
                    ]));
                  return JsPromptResponse(handledByClient: true,
                    action: v == null ? JsPromptResponseAction.CANCEL : JsPromptResponseAction.CONFIRM,
                    value: v ?? '');
                },
              ),
              if (_loading) const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      ),
    );
  }
}
