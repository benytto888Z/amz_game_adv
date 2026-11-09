import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Prépare localement le texte. L'envoi reste distinct et confirmé par le panneau.
class ProductPriceEditor extends StatefulWidget {
  const ProductPriceEditor({
    super.key,
    required this.enabled,
    required this.onPrepared,
  });
  final bool enabled;
  final ValueChanged<String> onPrepared;
  @override
  State<ProductPriceEditor> createState() => _ProductPriceEditorState();
}

class _ProductPriceEditorState extends State<ProductPriceEditor> {
  final _product = TextEditingController();
  final _price = TextEditingController();
  String _currency = 'EUR';
  String? _error;
  @override
  void dispose() {
    _product.dispose();
    _price.dispose();
    super.dispose();
  }

  void _prepare() {
    final name = _product.text.trim();
    final price = _price.text.trim();
    if (name.isEmpty || !RegExp(r'^[\x20-\x7E]+$').hasMatch(name)) {
      setState(() => _error = 'product_invalid_name'.tr);
      return;
    }
    final pattern = _currency == 'EUR'
        ? RegExp(r'^\d{1,9}([.,]\d{1,2})?$')
        : RegExp(r'^\d{1,9}$');
    if (!pattern.hasMatch(price)) {
      setState(
        () => _error =
            (_currency == 'EUR'
                    ? 'product_invalid_eur'
                    : 'product_invalid_fcfa')
                .tr,
      );
      return;
    }
    final parts = price.replaceAll(',', '.').split('.');
    // Conversion de la partie entière uniquement : aucune approximation flottante.
    final whole = int.parse(parts[0]).toString();
    final formatted = _currency == 'EUR'
        ? '$whole,${(parts.length == 2 ? parts[1] : '').padRight(2, '0')} EUR'
        : '$whole FCFA';
    final message = '$name - $formatted';
    if (message.length > 100) {
      setState(() => _error = 'product_too_long'.tr);
      return;
    }
    setState(() => _error = null);
    widget.onPrepared(message);
  }

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                child: Icon(
                  Icons.local_offer_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'product_title'.tr,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'product_explanation'.tr,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _product,
            enabled: widget.enabled,
            maxLength: 100,
            inputFormatters: [LengthLimitingTextInputFormatter(100)],
            decoration: InputDecoration(
              labelText: 'product_name'.tr,
              helperText: 'product_ascii'.tr,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _currency,
            decoration: InputDecoration(labelText: 'product_currency'.tr),
            items: const [
              DropdownMenuItem(value: 'EUR', child: Text('EUR')),
              DropdownMenuItem(value: 'FCFA', child: Text('FCFA')),
            ],
            onChanged: widget.enabled
                ? (v) {
                    if (v != null)
                      setState(() {
                        _currency = v;
                        _error = null;
                      });
                  }
                : null,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _price,
            enabled: widget.enabled,
            maxLength: 12,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'product_price'.tr,
              helperText:
                  (_currency == 'EUR'
                          ? 'product_eur_hint'
                          : 'product_fcfa_hint')
                      .tr,
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: widget.enabled ? _prepare : null,
            icon: const Icon(Icons.edit_outlined),
            label: Text('product_prepare'.tr),
          ),
        ],
      ),
    ),
  );
}
