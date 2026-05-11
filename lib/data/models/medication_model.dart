
class Medication {
  final int id;
  final String? code;
  final String name;          
  final String? genericName;  
  final String? laboratory;   
  final String? presentation; 
  final String? accionFarmacologica;
  final int? porcentaje;
  final String? seccion;
  
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
    this.accionFarmacologica,
    this.porcentaje,
    this.seccion,
    this.concentration,
    this.drugForm,
    this.contraindications,
    this.controlled = false,
  });

  String get displayName => name;

  String get subtitle {
    final parts = <String>[];
    if (genericName != null && genericName!.isNotEmpty) parts.add(genericName!);
    if (presentation != null && presentation!.isNotEmpty) parts.add(presentation!);
    return parts.join(' · ');
  }

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id:    json['id'],
      code:  json['code'],
      
      name:         json['nombre_comercial'] ?? json['name'] ?? '',
      genericName:  json['principio_activo'] ?? json['generic_name'],
      laboratory:   json['laboratorio']      ?? json['laboratory'],
      presentation: json['presentacion']     ?? json['presentation'],
      accionFarmacologica: json['accion_farmacologica'],
      porcentaje:   json['porcentaje'] != null ? (json['porcentaje'] as num).toInt() : null,
      seccion:      json['seccion'],
      concentration:     json['concentration'],
      drugForm:          json['drug_form'],
      contraindications: json['contraindications'],
      controlled: json['controlled'] == true || json['controlled'] == 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'nombre_comercial':      name,
        if (genericName != null)      'principio_activo':     genericName,
        if (laboratory != null)       'laboratorio':          laboratory,
        if (presentation != null)     'presentacion':         presentation,
        if (accionFarmacologica != null) 'accion_farmacologica': accionFarmacologica,
        if (porcentaje != null)       'porcentaje':           porcentaje,
        if (seccion != null)          'seccion':              seccion,
      };
}