# Mapbox Security Guidelines

## Token Security Best Practices

### 1. Token Storage

**✅ DO:**
- Store tokens in environment variables
- Use secure configuration management systems
- Implement token rotation policies
- Use different tokens for different environments

**❌ DON'T:**
- Commit tokens to version control
- Store tokens in plain text files
- Share tokens via email or chat
- Use production tokens in development

### 2. Access Token Types

#### Public Tokens
- Safe to use in client-side applications
- Can be exposed in frontend code
- Should have URL restrictions in production
- Limited to read-only operations

#### Secret Tokens
- Never expose in client-side code
- Use only on secure servers
- Required for administrative operations
- Store in secure server environments only

### 3. URL Restrictions

#### Development Environment
```
No restrictions (for testing)
```

#### Production Environment
```
https://yourdomain.com/*
https://www.yourdomain.com/*
https://app.yourdomain.com/*
```

#### Mobile Applications
```
No URL restrictions needed for mobile apps
Use bundle ID restrictions instead (iOS)
Use package name restrictions (Android)
```

### 4. Scope Configuration

#### Minimum Required Scopes
```
styles:read    - For map styles
fonts:read     - For map fonts
```

#### Optional Scopes
```
datasets:read  - For custom datasets
vision:read    - For advanced features
uploads:read   - For custom data uploads
```

#### Avoid Unnecessary Scopes
- Only grant required permissions
- Review scopes regularly
- Remove unused permissions

### 5. Token Rotation

#### Rotation Schedule
- Development tokens: Every 6 months
- Production tokens: Every 3 months
- Compromised tokens: Immediately

#### Rotation Process
1. Generate new token with same permissions
2. Update all applications/environments
3. Test functionality thoroughly
4. Delete old token
5. Monitor for any issues

### 6. Monitoring and Alerts

#### Usage Monitoring
- Set up usage alerts at 80% of limit
- Monitor for unusual traffic patterns
- Track API response errors
- Review access logs regularly

#### Security Monitoring
- Monitor for unauthorized usage
- Set up alerts for quota exceeded
- Track geographic usage patterns
- Review token access patterns

### 7. Environment-Specific Configuration

#### Development
```dart
class DevelopmentMapboxConfig {
  static const String accessToken = 'pk.eyJ1IjoiZGV2LXRva2VuLi4u';
  static const bool enableTelemetry = true;
  static const bool enableDebugMode = true;
}
```

#### Production
```dart
class ProductionMapboxConfig {
  static String get accessToken => 
    const String.fromEnvironment('MAPBOX_PROD_TOKEN');
  static const bool enableTelemetry = false;
  static const bool enableDebugMode = false;
}
```

### 8. Flutter-Specific Security

#### Android Configuration
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<meta-data
    android:name="MAPBOX_ACCESS_TOKEN"
    android:value="@string/mapbox_access_token" />
```

```xml
<!-- android/app/src/main/res/values/strings.xml -->
<string name="mapbox_access_token" translatable="false">
    YOUR_MAPBOX_ACCESS_TOKEN
</string>
```

#### iOS Configuration
```xml
<!-- ios/Runner/Info.plist -->
<key>MGLMapboxAccessToken</key>
<string>$(MAPBOX_ACCESS_TOKEN)</string>
```

### 9. Incident Response

#### If Token is Compromised
1. **Immediate Actions:**
   - Delete compromised token immediately
   - Generate new token with same permissions
   - Update all applications
   - Monitor usage for suspicious activity

2. **Investigation:**
   - Review access logs
   - Identify potential breach source
   - Document incident details
   - Implement additional security measures

3. **Prevention:**
   - Review security practices
   - Update token rotation schedule
   - Enhance monitoring systems
   - Train team on security best practices

### 10. Compliance Considerations

#### Data Privacy
- Disable telemetry in production if required
- Review data collection policies
- Implement user consent mechanisms
- Consider GDPR/CCPA requirements

#### Geographic Restrictions
- Some regions may have restrictions
- Review export control regulations
- Consider data residency requirements
- Implement geographic access controls

### 11. Testing Security

#### Security Testing Checklist
- [ ] Tokens not exposed in client-side code
- [ ] URL restrictions properly configured
- [ ] Environment variables properly set
- [ ] Token rotation process tested
- [ ] Usage monitoring configured
- [ ] Incident response plan documented

#### Automated Security Checks
```bash
# Check for exposed tokens in code
grep -r "pk\.eyJ" . --exclude-dir=node_modules

# Verify environment variables
echo $MAPBOX_ACCESS_TOKEN | head -c 20

# Test token validity
curl -s "https://api.mapbox.com/tokens/v2?access_token=$MAPBOX_ACCESS_TOKEN"
```

### 12. Documentation and Training

#### Team Training
- Security best practices
- Token management procedures
- Incident response protocols
- Regular security reviews

#### Documentation
- Keep security guidelines updated
- Document token management procedures
- Maintain incident response playbook
- Regular security audits

## Security Checklist

### Initial Setup
- [ ] Secure token generation
- [ ] Environment variable configuration
- [ ] URL restrictions configured
- [ ] Minimum required scopes only
- [ ] Usage monitoring enabled

### Ongoing Maintenance
- [ ] Regular token rotation
- [ ] Usage monitoring review
- [ ] Security audit quarterly
- [ ] Team training annually
- [ ] Incident response testing

### Production Deployment
- [ ] Production tokens configured
- [ ] URL restrictions verified
- [ ] Telemetry disabled
- [ ] Debug mode disabled
- [ ] Security monitoring active