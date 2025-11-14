resource "azurerm_application_gateway" "appgw" {
  # depends_on = [ azurerm_user_assigned_identity.app-gw-identity ]
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  zones = var.zones

  autoscale_configuration {
    min_capacity = var.min_capacity
    max_capacity = var.max_capacity
  }

  sku {
    name     = var.sku_name
    tier     = var.sku_tier
    # capacity = var.sku_capacity
  }

  gateway_ip_configuration {
    name      = var.gateway_ip_configuration_name
    subnet_id = var.subnet_id
  }

  dynamic "frontend_port" {
    for_each = var.frontend_ports
    content {
      name = frontend_port.value.name
      port = frontend_port.value.port
    }
  }

  dynamic "frontend_ip_configuration" {
    for_each = var.frontend_ip_configurations
    content {
      name                 = frontend_ip_configuration.value.name
      public_ip_address_id = azurerm_public_ip.pip.id
    }
  }

dynamic "backend_address_pool" {
    for_each = var.backend_address_pools
    content {
      name = backend_address_pool.value.name
      ip_addresses = backend_address_pool.value.ip_addresses
    }
  }


  dynamic "backend_http_settings" {
    for_each = var.backend_http_settings
    content {
      name                  = backend_http_settings.value.name
      cookie_based_affinity = backend_http_settings.value.cookie_based_affinity
      port                  = backend_http_settings.value.port
      protocol              = backend_http_settings.value.protocol
      request_timeout       = backend_http_settings.value.request_timeout
      probe_name            = backend_http_settings.value.probe_name
    }
  }

  dynamic "http_listener" {
    for_each = var.http_listeners
    content {
      name                           = http_listener.value.name
      frontend_ip_configuration_name = http_listener.value.frontend_ip_configuration_name
      frontend_port_name             = http_listener.value.frontend_port_name
      protocol                       = http_listener.value.protocol
      host_names                      = http_listener.value.host_names
    }
  }

    dynamic "http_listener" {
    for_each = var.https_listeners
    content {
      name                           = http_listener.value.name
      frontend_ip_configuration_name = http_listener.value.frontend_ip_configuration_name
      frontend_port_name             = http_listener.value.frontend_port_name
      protocol                       = http_listener.value.protocol
      host_names                      = http_listener.value.host_names
      # ssl_certificate_name = data.azurerm_key_vault_secret.kv_cert_secret_name.id
      ssl_certificate_name           = http_listener.value.ssl_certificate_name
      # ssl_certificate_name = "sslCert"
    }
  }
  #   ssl_certificate {
  #   name               = "sslCert"
  #   key_vault_secret_id = data.azurerm_key_vault_secret.kv_cert_secret_name1.id
  # }

  dynamic "ssl_certificate" {
    for_each = var.ssl_certificates
    content {
      name               = ssl_certificate.value.name
      key_vault_secret_id = ssl_certificate.value.key_vault_secret_id
    }
  }

  dynamic "request_routing_rule" {
    for_each = var.request_routing_rules
    content {
      name                       = request_routing_rule.value.name
      rule_type                  = "Basic"
      http_listener_name         = request_routing_rule.value.http_listener_name
      backend_address_pool_name  = request_routing_rule.value.backend_address_pool_name
      backend_http_settings_name = request_routing_rule.value.backend_http_settings_name
      priority                   = request_routing_rule.value.priority
      redirect_configuration_name = request_routing_rule.value.redirect_configuration_name
    }
  }

  dynamic "redirect_configuration" {
    for_each = var.redirect_configurations
    content {
      name        = redirect_configuration.value.name
      redirect_type = redirect_configuration.value.redirect_type
      target_listener_name = redirect_configuration.value.target_listener_name
      include_path = redirect_configuration.value.include_path
      include_query_string = redirect_configuration.value.include_query_string
    }
  }


   dynamic "probe" {
    for_each = var.probes
    content {
      name                = probe.value.name
      host                = probe.value.host
      path                = probe.value.path
      protocol            = probe.value.protocol
      interval            = probe.value.interval
      timeout             = probe.value.timeout
      unhealthy_threshold = probe.value.unhealthy_threshold
      pick_host_name_from_backend_http_settings = probe.value.pick_host_name_from_backend_http_settings 
      match {
        status_code = probe.value.status_code
      }
    }
  }

  firewall_policy_id = azurerm_web_application_firewall_policy.example.id



  identity {
    type = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.app-gw-identity.id ]
  }

  tags = var.tags
}

