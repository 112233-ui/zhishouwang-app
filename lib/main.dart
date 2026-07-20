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
              ),
              if (_loading) const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      ),
    );
  }
}
