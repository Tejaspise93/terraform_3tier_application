output "app_target_group_arn" {
  value = aws_lb_target_group.app_tg.arn
}

output "internal_alb_dns" {
  value = aws_lb.internal_alb.dns_name
}

output "internal_alb_arn" {
  value = aws_lb.internal_alb.arn
}