import 'package:club_india_user/views/legal%20page/terms_screen.dart';
import 'package:flutter/widgets.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  static const _sections = <LegalSection>[
    LegalSection(
      number: '1',
      title: 'Information We Collect',
      body: 'We collect the following categories of information:',
      bullets: [
        'Personal: Name, mobile number, email address',
        'Location: Precise GPS, approximate location, state/district/city',
        'Financial: Bank holder name, bank name, account number, IFSC code, UPI ID',
        'Rewards: Wallet balance, reward points, withdrawal & redemption history, transaction records',
        'Device: Device model, OS, app version, crash logs, network information',
        'Notification: Firebase FCM token, notification preferences',
      ],
    ),
    LegalSection(
      number: '2',
      title: 'How We Use Information',
      body: 'We use information to:',
      bullets: [
        'Create and manage accounts',
        'Verify identity',
        'Process rewards and withdrawals',
        'Prevent fraud',
        'Improve services',
        'Deliver notifications',
        'Provide customer support',
      ],
    ),
    LegalSection(
      number: '3',
      title: 'Location Data Usage',
      body:
          'Location information may be used to show nearby partner stores, improve user experience, verify service eligibility, and prevent fraudulent activity.',
    ),
    LegalSection(
      number: '4',
      title: 'Financial Data Usage',
      body:
          'Bank and UPI information may be used for withdrawal processing, account verification, and compliance requirements.',
    ),
    LegalSection(
      number: '5',
      title: 'Data Sharing',
      body:
          'We do not sell personal information. Information may be shared with authorized employees, service providers, banking partners, and government authorities when required by law.',
    ),
    LegalSection(
      number: '6',
      title: 'Data Security',
      body:
          'We implement reasonable security measures including authentication controls, access restrictions, secure communications, and fraud monitoring. However, no method of transmission is completely secure.',
    ),
    LegalSection(
      number: '7',
      title: 'Data Retention',
      body:
          'Information is retained as long as necessary for business operations, legal compliance, fraud prevention, and dispute resolution.',
    ),
    LegalSection(
      number: '8',
      title: 'User Rights',
      body:
          'Subject to applicable law, users may request access to personal information, correction of information, deletion of information, and information regarding processing activities.',
    ),
    LegalSection(
      number: '9',
      title: "Children's Privacy",
      body: 'The App is not intended for users under 18 years of age.',
    ),
    LegalSection(
      number: '10',
      title: 'Third-Party Services',
      body:
          'The App may use Firebase, cloud hosting services, notification services, and analytics and monitoring tools.',
    ),
    LegalSection(
      number: '11',
      title: 'Changes to Privacy Policy',
      body: 'We may update this Privacy Policy from time to time.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LegalPage(title: 'Privacy Policy', sections: _sections);
  }
}
