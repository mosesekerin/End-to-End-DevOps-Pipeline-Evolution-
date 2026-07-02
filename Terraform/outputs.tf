output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.notesapp.id
}

output "public_ip" {
  description = "Public IP address of the NotesApp server"
  value       = aws_eip.notesapp.public_ip
}

output "private_key_path" {
  description = "Path to the generated PEM file"
  value       = local_sensitive_file.private_key.filename
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ${var.key_name}.pem ec2-user@${aws_instance.notesapp.public_ip}"
}

output "notesapp_url" {
  description = "NotesApp endpoint URL"
  value       = "http://${aws_instance.notesapp.public_ip}:3000"
}
