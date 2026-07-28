/// Central, editable list of emergency / help contacts.
///
/// Kept in one place (safety requirement) so numbers are easy to audit and
/// update per region. Currently Germany. These power both the emergency-contact
/// urge technique and the (later) help screen.
class HelpContact {
  const HelpContact({
    required this.labelKey,
    required this.number,
  });

  /// AppLocalizations key for the human-readable label.
  final String labelKey;

  /// Dialable number (digits only, no spaces) for `tel:`.
  final String number;
}

/// Germany. ⚑ Verify/extend per region before shipping to other markets.
const List<HelpContact> kHelpContactsDe = <HelpContact>[
  HelpContact(labelKey: 'helpTelefonseelsorge1', number: '08001110111'),
  HelpContact(labelKey: 'helpTelefonseelsorge2', number: '08001110222'),
  HelpContact(labelKey: 'helpSuchtHotline', number: '01806313031'),
  HelpContact(labelKey: 'helpEmergency', number: '112'),
];
