class Credentials {
  final String server;
  final String username;
  final String password;
  final String site;
  final bool ignoreCertificate;

  Credentials(this.server, this.username, this.password, this.site,
      this.ignoreCertificate);
}
