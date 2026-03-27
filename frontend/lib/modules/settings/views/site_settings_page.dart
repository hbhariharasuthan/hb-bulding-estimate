import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';

import '../../../core/config/api_config.dart';
import '../../../core/utils/picked_upload.dart';
import '../../../core/utils/web_image_picker.dart';
import '../../../shared/widgets/app_footer.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/module_page_header.dart';
import '../../../shared/widgets/page_container.dart';
import '../providers/site_settings_provider.dart';

class SiteSettingsPage extends StatefulWidget {
  const SiteSettingsPage({super.key});

  @override
  State<SiteSettingsPage> createState() => _SiteSettingsPageState();
}

class _SiteSettingsPageState extends State<SiteSettingsPage> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _razorKeyCtrl = TextEditingController();
  final _razorSecretCtrl = TextEditingController();

  bool _initialized = false;
  bool _saving = false;
  String? _emailError;
  String? _phoneError;
  PickedUpload? _siteLogoFile;
  PickedUpload? _loginBgFile;
  bool _removeCurrentLogo = false;
  bool _removeCurrentBackground = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _contactCtrl.dispose();
    _razorKeyCtrl.dispose();
    _razorSecretCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickSiteLogo() async {
    try {
      final file = await pickImageForWeb();
      if (file == null) return;
      setState(() {
        _siteLogoFile = file;
        _removeCurrentLogo = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open file picker: $e')),
      );
    }
  }

  Future<void> _pickLoginBackground() async {
    try {
      final file = await pickImageForWeb();
      if (file == null) return;
      setState(() {
        _loginBgFile = file;
        _removeCurrentBackground = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open file picker: $e')),
      );
    }
  }

  MultipartFile? _toMultipart(PickedUpload? file) {
    final bytes = file?.bytes;
    final name = file?.name;
    if (bytes == null || name == null) return null;
    return MultipartFile.fromBytes(bytes, filename: name);
  }

  String? _validateEmail(String value) {
    if (value.trim().isEmpty) return null;
    final email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!email.hasMatch(value.trim())) return 'Enter a valid email';
    return null;
  }

  String? _validatePhone(String value) {
    if (value.trim().isEmpty) return null;
    final phone = RegExp(r'^[0-9+\-\s()]{7,20}$');
    if (!phone.hasMatch(value.trim())) return 'Enter a valid phone number';
    return null;
  }

  Future<void> _save() async {
    final emailError = _validateEmail(_emailCtrl.text);
    final phoneError = _validatePhone(_contactCtrl.text);
    setState(() {
      _emailError = emailError;
      _phoneError = phoneError;
    });
    if (emailError != null || phoneError != null) return;

    setState(() => _saving = true);
    try {
      await context.read<SiteSettingsProvider>().save(
            siteName: _nameCtrl.text.trim(),
            siteAdminEmail: _emailCtrl.text.trim(),
            siteAdminContactNumber: _contactCtrl.text.trim(),
            razorpayKey: _razorKeyCtrl.text.trim(),
            razorpaySecret: _razorSecretCtrl.text.trim(),
            siteLogo: _removeCurrentLogo ? null : _toMultipart(_siteLogoFile),
            loginBackground:
                _removeCurrentBackground ? null : _toMultipart(_loginBgFile),
            removeSiteLogo: _removeCurrentLogo,
            removeLoginBackground: _removeCurrentBackground,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Site settings saved')),
      );
      setState(() {
        _siteLogoFile = null;
        _loginBgFile = null;
        _removeCurrentLogo = false;
        _removeCurrentBackground = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SiteSettingsProvider>();
    final settings = provider.settings;
    if (!_initialized) {
      _nameCtrl.text = settings?.siteName ?? '';
      _emailCtrl.text = settings?.siteAdminEmail ?? '';
      _contactCtrl.text = settings?.siteAdminContactNumber ?? '';
      _razorKeyCtrl.text = settings?.razorpayKey ?? '';
      _razorSecretCtrl.text = settings?.razorpaySecret ?? '';
      _initialized = true;
    }

    return Scaffold(
      appBar: const AppHeader(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1300),
              child: const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: ModulePageHeader(
                  title: 'Site Settings',
                  breadcrumbs: ['SETTINGS', 'SITE SETTINGS'],
                ),
              ),
            ),
          ),
          Expanded(
            child: PageContainer(
              maxWidth: 1300,
              child: ListView(
                children: [
                  const SizedBox(height: 4),
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Site Name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailCtrl,
                    decoration: InputDecoration(
                      labelText: 'Site Admin Email',
                      errorText: _emailError,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _contactCtrl,
                    decoration: InputDecoration(
                      labelText: 'Site Admin Contact Number',
                      errorText: _phoneError,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _razorKeyCtrl,
                    decoration: const InputDecoration(labelText: 'Razorpay Key'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _razorSecretCtrl,
                    decoration: const InputDecoration(labelText: 'Razorpay Secret'),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _pickSiteLogo,
                        icon: const Icon(Icons.upload_file),
                        label: Text(
                          _siteLogoFile == null
                              ? 'Upload Site Logo'
                              : 'Logo: ${_siteLogoFile!.name}',
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _pickLoginBackground,
                        icon: const Icon(Icons.image),
                        label: Text(
                          _loginBgFile == null
                              ? 'Upload Login Background'
                              : 'Background: ${_loginBgFile!.name}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_siteLogoFile?.bytes != null) ...[
                    const Text('Selected Site Logo Preview'),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 120,
                      child: Image.memory(_siteLogoFile!.bytes, fit: BoxFit.contain),
                    ),
                    const SizedBox(height: 12),
                  ] else if (settings?.siteLogo?.isNotEmpty == true && !_removeCurrentLogo) ...[
                    const Text('Current Site Logo'),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 120,
                      child: Image.network(
                        ApiConfig.buildUri(settings!.siteLogo!).toString(),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Text('Unable to load current logo'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      value: _removeCurrentLogo,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Remove current logo'),
                      onChanged: (v) => setState(() {
                        _removeCurrentLogo = v ?? false;
                        if (_removeCurrentLogo) _siteLogoFile = null;
                      }),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_loginBgFile?.bytes != null) ...[
                    const Text('Selected Login Background Preview'),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 120,
                      child: Image.memory(_loginBgFile!.bytes, fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 12),
                  ] else if (settings?.loginBackground?.isNotEmpty == true &&
                      !_removeCurrentBackground) ...[
                    const Text('Current Login Background'),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 120,
                      child: Image.network(
                        ApiConfig.buildUri(settings!.loginBackground!).toString(),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Text('Unable to load current background'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      value: _removeCurrentBackground,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Remove current background'),
                      onChanged: (v) => setState(() {
                        _removeCurrentBackground = v ?? false;
                        if (_removeCurrentBackground) _loginBgFile = null;
                      }),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(_saving ? 'Saving...' : 'Save Settings'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const AppFooter(),
        ],
      ),
    );
  }
}
