class Credentials {
  final String protocol;
  final String server;
  final String username;
  final String password;
  final String site;
  final bool ignoreCertificate;

  Credentials(this.protocol, this.server, this.username, this.password,
      this.site, this.ignoreCertificate);
}
