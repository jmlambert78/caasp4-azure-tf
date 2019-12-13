resource "azurerm_dns_zone" "jmllabsuse" {
  name                = "jmllabsuse.com"
  resource_group_name = "jmllabsusedns-rg"
}
resource "azurerm_private_dns_zone" "jmllabsuse-private" {
  name                = "private.jmllabsuse.com"
  resource_group_name = "caasp4tf-eu2-rg"
}
