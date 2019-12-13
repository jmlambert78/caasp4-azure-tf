
resource "azurerm_resource_group" "caasp4tf-lb-rg" {
  name     = "caasp4tf-lb-rg"
  location = var.azure-region
}

resource "azurerm_public_ip" "caasp4tf-ip-lb" {
  name                = "caasp4tf-ip-lb"
  location            = var.azure-region
  resource_group_name = azurerm_resource_group.caasp4tf-lb-rg.name
  allocation_method   = "Static"
}
  data "azurerm_public_ip" "caasp4tf-ip-lb" {
  name                = azurerm_public_ip.caasp4tf-ip-lb.name
  resource_group_name = azurerm_resource_group.caasp4tf-lb-rg.name
}
output "public_ip_address-lb" {
  value = data.azurerm_public_ip.caasp4tf-ip-lb.ip_address
}
resource "azurerm_dns_a_record" "lbdomain" {
  name                = "caasp4-lbdomain"
  zone_name           = azurerm_dns_zone.jmllabsuse.name
  resource_group_name = azurerm_dns_zone.jmllabsuse.resource_group_name
  ttl                 = 300
  records             = ["${data.azurerm_public_ip.caasp4tf-ip-lb.ip_address}"]
}
resource "azurerm_lb" "caasp4-lb" {
  name                = "CaaSP4LoadBalancer"
  location            = var.azure-region
  resource_group_name = azurerm_resource_group.caasp4tf-lb-rg.name

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.caasp4tf-ip-lb.id
  }
}

resource "azurerm_lb_backend_address_pool" "caasp4-lb-backpool" {
  resource_group_name = azurerm_resource_group.caasp4tf-lb-rg.name
  loadbalancer_id     = azurerm_lb.caasp4-lb.id
  name                = "acctestpool"
}

resource "azurerm_network_interface_backend_address_pool_association" "master" {
  network_interface_id    = azurerm_network_interface.caasp4tf-nics[1].id
  ip_configuration_name   = "caasp4tf-NicConfiguration-master1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.caasp4-lb-backpool.id
}

variable "list-ports"{
 default =["22","443","6443","8443","80","2222","2793"] 
}

resource "azurerm_lb_rule" "lb-rules" {
  resource_group_name            = azurerm_resource_group.caasp4tf-lb-rg.name
  loadbalancer_id                = azurerm_lb.caasp4-lb.id
  name                           = "LBRule-${var.list-ports[count.index]}"
  protocol                       = "Tcp"
  frontend_port                  = var.list-ports[count.index]
  backend_port                   = var.list-ports[count.index]
  backend_address_pool_id        = azurerm_lb_backend_address_pool.caasp4-lb-backpool.id
  frontend_ip_configuration_name = "PublicIPAddress"
  count                          = length(var.list-ports)
}
resource "azurerm_lb_probe" "lb-probes" {
  resource_group_name = azurerm_resource_group.caasp4tf-lb-rg.name
  loadbalancer_id     = azurerm_lb.caasp4-lb.id
  name                = "LB-probe-${var.list-ports[count.index]}"
  port                = var.list-ports[count.index]
  count               = length(var.list-ports)
}


