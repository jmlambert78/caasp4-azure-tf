resource "azurerm_dns_zone" "jmllabsuse" {
  name                = "jmllabsuse.com"
  resource_group_name = var.caasp4_dns_rg_name
}
resource "azurerm_private_dns_zone" "jmllabsuse-private" {
  name                = "private.jmllabsuse.com"
  resource_group_name = var.caasp4_rg_name
}
