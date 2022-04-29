module "lb" {
  load_balancers = {
    lb-01 = {
      add_lb_security_group_rules = true
      internal                    = false
      load_balancer_type          = "application"
      security_group              = "terraform-public"
      subnets                     = ["terraform-public-01", "terraform-public-02"]
      listeners = [
        /*
        {
          port         = 443
          protocol     = "HTTPS"
          target_group = "group2"
        },
        */
        {
          port         = 80
          protocol     = "HTTP"
          target_group = "group1"
        },
      ]
      tags = {
      }
    }
  }

  target_groups = {

    /*

    Instances will be added to target groups based on the tag defined by instance_tag_prefix, e.g.:
      instance tag: terraform_target_group_group1 = "true"
      instance_tag_prefix = "terraform_target_group_"
      The resource definition will then look for any instance with the tag 'terraform_target_group_group1' defined.

    */
    group1 = {
      add_instance_security_group_rules = true
      instance_tag_prefix               = "terraform_target_group_"
      port                              = 80
      protocol                          = "HTTP"
    },
    group2 = {
      add_instance_security_group_rules = true
      instance_tag_prefix               = "terraform_target_group_"
      port                              = 443
      protocol                          = "HTTPS"
    },

  }

  # do not edit this block
  source = "../../../modules/lb/"
  vpc    = var.vpc

}