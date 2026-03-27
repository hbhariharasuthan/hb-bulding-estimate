class SiteSettings {
  SiteSettings({
    required this.id,
    this.siteName,
    this.siteAdminEmail,
    this.siteLogo,
    this.loginBackground,
    this.siteAdminContactNumber,
    this.razorpayKey,
    this.razorpaySecret,
  });

  final int id;
  final String? siteName;
  final String? siteAdminEmail;
  final String? siteLogo;
  final String? loginBackground;
  final String? siteAdminContactNumber;
  final String? razorpayKey;
  final String? razorpaySecret;

  factory SiteSettings.fromJson(Map<String, dynamic> json) => SiteSettings(
        id: json['id'] as int,
        siteName: json['site_name']?.toString(),
        siteAdminEmail: json['site_admin_email']?.toString(),
        siteLogo: json['site_logo']?.toString(),
        loginBackground: json['login_background']?.toString(),
        siteAdminContactNumber: json['site_admin_contact_number']?.toString(),
        razorpayKey: json['razorpay_key']?.toString(),
        razorpaySecret: json['razorpay_secret']?.toString(),
      );
}
