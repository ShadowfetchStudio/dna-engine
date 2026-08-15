import Foundation
import WebKit

@MainActor
final class OfflinePDFRenderer: NSObject, WKNavigationDelegate {
    private var webView: WKWebView?
    private var completion: ((Result<Data, Error>) -> Void)?
    private var completed = false

    func render(html: String, completion: @escaping (Result<Data, Error>) -> Void) {
        cancel()
        self.completion = completion
        completed = false

        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
        configuration.defaultWebpagePreferences.allowsContentJavaScript = false

        let view = WKWebView(
            frame: CGRect(x: 0, y: 0, width: 794, height: 1123),
            configuration: configuration
        )
        view.navigationDelegate = self
        webView = view
        view.loadHTMLString(html, baseURL: nil)
    }

    func cancel() {
        webView?.stopLoading()
        webView?.navigationDelegate = nil
        webView = nil
        completion = nil
        completed = true
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard !completed, webView === self.webView else { return }
        webView.createPDF(configuration: WKPDFConfiguration()) { [weak self] result in
            Task { @MainActor in
                guard let self, !self.completed, webView === self.webView else { return }
                self.finish(result)
            }
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        finish(.failure(error))
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        finish(.failure(error))
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        let url = navigationAction.request.url
        let isLocalDocument = url == nil || url?.scheme == "about"
        decisionHandler(isLocalDocument ? .allow : .cancel)
        if !isLocalDocument {
            finish(.failure(OfflinePDFError.externalNavigationBlocked))
        }
    }

    private func finish(_ result: Result<Data, Error>) {
        guard !completed else { return }
        completed = true
        let callback = completion
        completion = nil
        webView?.navigationDelegate = nil
        webView = nil
        callback?(result)
    }
}

enum OfflinePDFError: LocalizedError {
    case externalNavigationBlocked

    var errorDescription: String? {
        "PDF rendering blocked an unexpected external navigation."
    }
}
