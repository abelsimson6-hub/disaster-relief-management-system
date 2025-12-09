from django.db import models

class Communication(models.Model):
    MESSAGE_TYPE_CHOICES = [
        ('text', 'Text'),
        ('image', 'Image'),
        ('video', 'Video'),
        ('document', 'Document'),
    ]
    STATUS_CHOICES = [
        ('sent', 'Sent'),
        ('delivered', 'Delivered'),
        ('read', 'Read'),
    ]
    id = models.AutoField(primary_key=True)
    sender = models.ForeignKey('users.User', on_delete=models.CASCADE, related_name='sent_messages')
    receiver = models.ForeignKey('users.User', on_delete=models.CASCADE, related_name='received_messages')
    message_type = models.CharField(max_length=10, choices=MESSAGE_TYPE_CHOICES, default='text')
    content = models.TextField()
    sent_at = models.DateTimeField(auto_now_add=True)
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='sent')

    class Meta:
        db_table = 'communications'
        indexes = [
            models.Index(fields=['sender', 'receiver']),
            models.Index(fields=['status', 'sent_at']),
        ]
        constraints = [
            models.CheckConstraint(
                check=models.Q(message_type__in=['text', 'image', 'video', 'document']),
                name='valid_message_type'
            ),
            models.CheckConstraint(
                check=models.Q(status__in=['sent', 'delivered', 'read']),
                name='valid_message_status'
            )
        ]

    def __str__(self):
        return f"{self.sender.username} -> {self.receiver.username}: {self.content[:20]}..."