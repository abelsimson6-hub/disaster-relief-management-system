from django.db import models

class Alert(models.Model):
    SEVERITY_CHOICES = [
        ('low', 'Low'),
        ('medium', 'Medium'),
        ('high', 'High'),
        ('critical', 'Critical'),
    ]
    STATUS_CHOICES = [
        ('active', 'Active'),
        ('resolved', 'Resolved'),
        ('cancelled', 'Cancelled'),
    ]

    id = models.AutoField(primary_key=True)
    Disasters = models.ForeignKey('disasters.Disasters', on_delete=models.CASCADE)
    title = models.CharField(max_length=200)
    description = models.TextField()
    severity = models.CharField(max_length=10, choices=SEVERITY_CHOICES, default='medium')
    issued_at = models.DateTimeField(auto_now_add=True)
    resolved_at = models.DateTimeField(null=True, blank=True)
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='active')

    class Meta:
        db_table = 'alerts'
        indexes = [
            models.Index(fields=['severity', 'status']),
            models.Index(fields=['issued_at']),
        ]
        constraints = [
            models.CheckConstraint(
                check=models.Q(severity__in=['low', 'medium', 'high', 'critical']),
                name='valid_alert_severity'
            ),
            models.CheckConstraint(
                check=models.Q(status__in=['active', 'resolved', 'cancelled']),
                name='valid_alert_status'
            )
        ]

    def __str__(self):
        return f"{self.title} ({self.severity})"