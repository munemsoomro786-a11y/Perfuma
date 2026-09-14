import 'dart:io';
void main() {
  String content = File('lib/main.dart').readAsStringSync();
  content = content.replaceAll(r"context.push('/product/$($widget.product.id)')", r"context.push('/product/${widget.product.id}')");
  File('lib/main.dart').writeAsStringSync(content);
}
