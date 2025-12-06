from django.db import models
from django.core.validators import MinValueValidator, MaxValueValidator

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


class AlertStatusHistory(models.Model):
    """Audit trail for alert lifecycle changes."""
    id = models.AutoField(primary_key=True)
    alert = models.ForeignKey(Alert, on_delete=models.CASCADE, related_name='status_history')
    previous_status = models.CharField(max_length=10, choices=Alert.STATUS_CHOICES)
    new_status = models.CharField(max_length=10, choices=Alert.STATUS_CHOICES)
    changed_by = models.ForeignKey('users.User', on_delete=models.SET_NULL, null=True, blank=True)
    note = models.TextField(blank=True)
    changed_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'alert_status_history'
        indexes = [
            models.Index(fields=['alert']),
            models.Index(fields=['new_status', 'changed_at']),
        ]

    def __str__(self):
        return f"Alert {self.alert_id}: {self.previous_status}->{self.new_status}"


class WeatherAlert(models.Model):
    """Weather risk and alert model for disaster prevention"""
    RISK_LEVEL_CHOICES = [
        ('low', 'Low'),
        ('moderate', 'Moderate'),
        ('high', 'High'),
        ('extreme', 'Extreme'),
    ]
    WEATHER_TYPE_CHOICES = [
        ('hurricane', 'Hurricane'),
        ('flood', 'Flood'),
        ('drought', 'Drought'),
        ('storm', 'Storm'),
        ('tornado', 'Tornado'),
        ('heatwave', 'Heatwave'),
        ('coldwave', 'Coldwave'),
        ('tsunami', 'Tsunami'),
        ('other', 'Other'),
    ]
    STATUS_CHOICES = [
        ('forecast', 'Forecast'),
        ('active', 'Active'),
        ('warning', 'Warning'),
        ('expired', 'Expired'),
    ]

    id = models.AutoField(primary_key=True)
    weather_type = models.CharField(max_length=20, choices=WEATHER_TYPE_CHOICES)
    risk_level = models.CharField(max_length=20, choices=RISK_LEVEL_CHOICES, default='moderate')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='forecast')
    location = models.CharField(max_length=255)
    latitude = models.DecimalField(
        max_digits=9, decimal_places=6, null=True, blank=True,
        validators=[MinValueValidator(-90), MaxValueValidator(90)]
    )
    longitude = models.DecimalField(
        max_digits=9, decimal_places=6, null=True, blank=True,
        validators=[MinValueValidator(-180), MaxValueValidator(180)]
    )
    title = models.CharField(max_length=200)
    description = models.TextField()
    forecast_date = models.DateTimeField()
    expected_severity = models.CharField(max_length=20, choices=Alert.SEVERITY_CHOICES, default='medium')
    affected_radius_km = models.DecimalField(
        max_digits=10, decimal_places=2, null=True, blank=True,
        validators=[MinValueValidator(0)]
    )
    wind_speed_kmh = models.DecimalField(
        max_digits=6, decimal_places=2, null=True, blank=True,
        validators=[MinValueValidator(0)]
    )
    rainfall_mm = models.DecimalField(
        max_digits=8, decimal_places=2, null=True, blank=True,
        validators=[MinValueValidator(0)]
    )
    temperature_celsius = models.DecimalField(
        max_digits=5, decimal_places=2, null=True, blank=True,
        validators=[MinValueValidator(-50), MaxValueValidator(60)]
    )
    issued_by = models.ForeignKey(
        'users.User',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        limit_choices_to={'role__in': ['super_admin', 'camp_admin']}
    )
    issued_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    expires_at = models.DateTimeField(null=True, blank=True)
    related_disaster = models.ForeignKey(
        'disasters.Disasters',
        on_delete=models.SET_NULL,
        null=True,
        blank=True
    )

    class Meta:
        db_table = 'weather_alerts'
        indexes = [
            models.Index(fields=['weather_type', 'risk_level']),
            models.Index(fields=['status', 'forecast_date']),
            models.Index(fields=['risk_level', 'status']),
        ]
        constraints = [
            models.CheckConstraint(
                check=models.Q(weather_type__in=['hurricane', 'flood', 'drought', 'storm', 'tornado', 'heatwave', 'coldwave', 'tsunami', 'other']),
                name='valid_weather_type'
            ),
            models.CheckConstraint(
                check=models.Q(risk_level__in=['low', 'moderate', 'high', 'extreme']),
                name='valid_risk_level'
            ),
            models.CheckConstraint(
                check=models.Q(status__in=['forecast', 'active', 'warning', 'expired']),
                name='valid_weather_status'
            ),
        ]
        ordering = ['-forecast_date', '-risk_level']

    def __str__(self):
        return f"{self.title} - {self.weather_type} ({self.risk_level})"


class WeatherAlertStatusHistory(models.Model):
    """Tracks weather alert status transitions."""
    id = models.AutoField(primary_key=True)
    weather_alert = models.ForeignKey(WeatherAlert, on_delete=models.CASCADE, related_name='status_history')
    previous_status = models.CharField(max_length=20, choices=WeatherAlert.STATUS_CHOICES)
    new_status = models.CharField(max_length=20, choices=WeatherAlert.STATUS_CHOICES)
    changed_by = models.ForeignKey('users.User', on_delete=models.SET_NULL, null=True, blank=True)
    note = models.TextField(blank=True)
    changed_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'weather_alert_status_history'
        indexes = [
            models.Index(fields=['weather_alert']),
            models.Index(fields=['new_status', 'changed_at']),
        ]

    def __str__(self):
        return f"WeatherAlert {self.weather_alert_id}: {self.previous_status}->{self.new_status}"