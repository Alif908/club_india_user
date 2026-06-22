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
      title: 'Legal Basis for Processing',
      body:
          'We process personal information for legitimate business purposes, including providing services requested by users, managing rewards and withdrawals, fraud prevention, security monitoring, compliance with legal obligations, and improving App functionality.',
    ),
    LegalSection(
      number: '4',
      title: 'Location Data Usage',
      body:
          'Location information may be used to show nearby partner stores, improve user experience, verify service eligibility, and prevent fraudulent activity. Location access may be disabled through device settings; however, certain features may not function properly.',
    ),
    LegalSection(
      number: '5',
      title: 'Financial Data Usage',
      body:
          'Bank and UPI information may be used for withdrawal processing, identity verification, compliance requirements, and fraud prevention. Financial information is accessed only when necessary for providing services.',
    ),
    LegalSection(
      number: '6',
      title: 'Notifications',
      body: 'The App may send:',
      bullets: [
        'Promotional notifications',
        'Reward notifications',
        'Transaction alerts',
        'Security alerts',
        'System announcements',
      ],
    ),
    LegalSection(
      number: '7',
      title: 'OTP Authentication',
      body:
          'To access certain features, users may be required to verify their mobile number using OTP authentication. Users are responsible for protecting OTP codes and must not share OTPs with others.',
    ),
    LegalSection(
      number: '8',
      title: 'Data Sharing',
      body:
          'We do not sell personal information. Information may be shared with authorized employees, service providers, banking and payment partners, cloud service providers, and government authorities when required by law.',
    ),
    LegalSection(
      number: '9',
      title: 'Third-Party Services',
      body:
          'The App may use Firebase, cloud hosting providers, notification services, analytics services, and monitoring services. Firebase services provided by Google may collect device identifiers, notification tokens, and diagnostic information according to Google\'s policies.',
    ),
    LegalSection(
      number: '10',
      title: 'Data Security',
      body:
          'We implement reasonable security measures including authentication controls, access restrictions, secure communications, and fraud monitoring. However, no method of transmission or storage is completely secure.',
    ),
    LegalSection(
      number: '11',
      title: 'Data Retention',
      body:
          'Information is retained as long as necessary for business operations, rewards management, withdrawal processing, legal compliance, fraud prevention, financial record keeping, and dispute resolution.',
    ),
    LegalSection(
      number: '12',
      title: 'User Rights',
      body:
          'Subject to applicable law, users may request access to personal information, correction of information, deletion of information, and information regarding processing activities. Requests may be submitted through the contact information provided below.',
    ),
    LegalSection(
      number: '13',
      title: 'Account Deletion',
      body:
          'Users may request account deletion at any time through https://coinapi.bestagencyindia.com/delete-user.html or by contacting support. Upon deletion, user profile information will be removed and access to the App will be terminated. Reward balances may be forfeited. Certain information may be retained where necessary for legal obligations, fraud prevention, financial record retention, security investigations, and dispute resolution.',
    ),
    LegalSection(
      number: '14',
      title: "Children's Privacy",
      body:
          'The App is not intended for individuals under 18 years of age. We do not knowingly collect personal information from children under 18. If such information is identified, it will be removed where legally permitted.',
    ),
    LegalSection(
      number: '15',
      title: 'Google Play Data Safety Disclosure',
      body: 'The App may collect:',
      bullets: [
        'Name',
        'Phone number',
        'Email address',
        'Location information',
        'Financial information',
        'Reward information',
        'Transaction information',
        'Device information',
        'Notification token',
      ],
    ),
    LegalSection(
      number: '16',
      title: 'Changes to Privacy Policy',
      body:
          'We may update this Privacy Policy from time to time. Changes become effective when published within the App or on associated platforms. Continued use of the App constitutes acceptance of the updated Privacy Policy.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LegalPage(title: 'Privacy Policy', sections: _sections);
  }
}
