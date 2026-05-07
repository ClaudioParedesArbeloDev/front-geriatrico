class Medication {
  final int id;
  final String? code;
  final String name;
  final String? genericName;
  final String? laboratory;
  final String? presentation;
  final String? concentration;
  final String? drugForm;
  final String? contraindications;
  final bool controlled;

  const Medication({
    required this.id,
    this.code,
    required this.name,
    this.genericName,
    this.laboratory,
    this.presentation,
    this.concentration,
    this.drugForm,
    this.contraindications,
    this.controlled = false,
  });

  String get drugFormLabel => switch (drugForm) {
        'tablet'      => 'Comprimido',
        'capsule'     => 'Cápsula',
        'syrup'       => 'Jarabe',
        'injectable'  => 'Inyectable',
        'drops'       => 'Gotas',
        'cream'       => 'Crema',
        'patch'       => 'Parche',
        'suppository' => 'Supositorio',
        'inhaler'     => 'Inhalador',
        'other'       => 'Otro',
        _             => drugForm ?? '',
      };

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id:               json['id'],
      code:             json['code'],
      name:             json['name'] ?? '',
      genericName:      json['generic_name'],
      laboratory:       json['laboratory'],
      presentation:     json['presentation'],
      concentration:    json['concentration'],
      drugForm:         json['drug_form'],
      contraindications: json['contraindications'],
      controlled:       json['controlled'] == true || json['controlled'] == 1,
    );
  }

  Map<String, dynamic> toJson() => {
        if (code != null)              'code':              code,
        'name':                        name,
        if (genericName != null)       'generic_name':      genericName,
        if (laboratory != null)        'laboratory':        laboratory,
        if (presentation != null)      'presentation':      presentation,
        if (concentration != null)     'concentration':     concentration,
        if (drugForm != null)          'drug_form':         drugForm,
        if (contraindications != null) 'contraindications': contraindications,
        'controlled':                  controlled,
      };
}
