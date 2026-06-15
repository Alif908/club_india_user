import 'package:club_india_user/views/legal%20page/terms_screen.dart';
import 'package:flutter/widgets.dart';

class AdditionalLegalPoliciesPage extends StatelessWidget {
  const AdditionalLegalPoliciesPage({super.key});

  static const _sections = <LegalSection>[
    LegalSection(
      number: '§1',
      title: 'Data Deletion Policy',
      body:
          'Users may request deletion of personal information by contacting Bestagencyindia2026@gmail.com. The Company may retain information where required for legal obligations, fraud prevention, security investigations, financial records, and dispute resolution.',
    ),
    LegalSection(
      number: '§2',
      title: 'OTP Authentication Policy',
      body:
          'Users must register a valid mobile number, complete OTP verification, and protect OTP codes. Users must not share OTPs, use another person\'s mobile number, or attempt unauthorized access.',
    ),
    LegalSection(
      number: '§3',
      title: 'GPS Location Consent',
      body:
          'By enabling location services, users consent to collection and processing of location information for operational purposes.',
    ),
    LegalSection(
      number: '§4',
      title: 'Rewards Abuse Policy',
      body:
          'The Company may suspend accounts involved in fake referrals, multiple account creation, reward manipulation, and fraudulent transactions.',
    ),
    LegalSection(
      number: '§5',
      title: 'Withdrawal Policy',
      body:
          'Withdrawals may be subject to identity verification, fraud checks, and operational review. The Company may reject withdrawal requests that violate Company policies.',
    ),
    LegalSection(
      number: '§6',
      title: 'Notification Policy',
      body:
          'The App may send promotional notifications, transaction alerts, security notifications, and system announcements. Users may manage notification settings from their device.',
    ),
    LegalSection(
      number: '§7',
      title: 'Google Play Data Safety Disclosure',
      body:
          'Data collected includes name, phone number, email address, location data, financial information, reward information, device information, and notification token. Purpose: authentication, rewards management, fraud prevention, security, notifications, and app functionality. The Company does not sell personal information.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LegalPage(title: 'Additional Legal Policies', sections: _sections);
  }
}
