import 'package:flutter/material.dart';
import 'package:app_geriatrico/core/app_colors.dart';
import 'package:app_geriatrico/data/models/medication_model.dart';
import 'package:app_geriatrico/data/repositories/medication_repository.dart';
import 'package:app_geriatrico/services/api_services.dart';
import 'package:app_geriatrico/core/config.dart';

class MedicationsScreen extends StatefulWidget {
  final String token;
  const MedicationsScreen({super.key, required this.token});

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  late final ApiService    _api;
  late final MedicationRepository _repo;

  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  List<Medication> _meds    = [];
  bool _loading             = true;
  String? _error;
  String _query             = '';

  
  static const _bg       = Color(0xFF1E0619);
  static const _surface  = Color(0xFF2A0825);
  static const _card     = Color(0xFF3A0B32);
  static const _accent   = Color(0xFF7B2268);
  static const _border   = Color(0x1FFFFFFF);

  @override
  void initState() {
    super.initState();
    _api  = ApiService(baseUrl: ApiConfig.baseUrl, token: widget.token);
    _repo = MedicationRepository(_api);
    _load();
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearch);
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  
  Future<void> _load({String? search}) async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await _repo.getAll(search: search);
      if (mounted) setState(() { _meds = results; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  void _onSearch() {
    final q = _searchCtrl.text.trim();
    if (q == _query) return;
    _query = q;
    _load(search: q.isEmpty ? null : q);
  }

  
  void _snack(String msg, {bool ok = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: ok ? const Color(0xFF2E7D32) : AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  
  Future<void> _showForm({Medication? med}) async {
    final isEdit        = med != null;
    final nameCtrl      = TextEditingController(text: med?.name      ?? '');
    final princCtrl     = TextEditingController(text: med?.genericName ?? '');
    final labCtrl       = TextEditingController(text: med?.laboratory  ?? '');
    final presCtrl      = TextEditingController(text: med?.presentation ?? '');
    final formKey       = GlobalKey<FormState>();
    bool saving         = false;

    InputDecoration input(String label, {bool required = false}) => InputDecoration(
      labelText: required ? '$label *' : label,
      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 13),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.white54),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.error),
      ),
    );

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [

             
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

             
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Row(children: [
                  Icon(Icons.medication_outlined,
                      color: Colors.white.withValues(alpha: 0.55), size: 18),
                  const SizedBox(width: 10),
                  Text(isEdit ? 'Editar medicamento' : 'Nuevo medicamento',
                      style: const TextStyle(color: Colors.white, fontSize: 16,
                          fontWeight: FontWeight.w300)),
                  const Spacer(),
                  if (saving)
                    const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white38))
                  else
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: Colors.white),
                      child: Text(isEdit ? 'Guardar' : 'Crear',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        setS(() => saving = true);
                        try {
                          final payload = {
                            'nombre_comercial': nameCtrl.text.trim(),
                            if (princCtrl.text.trim().isNotEmpty)
                              'principio_activo': princCtrl.text.trim(),
                            if (labCtrl.text.trim().isNotEmpty)
                              'laboratorio': labCtrl.text.trim(),
                            if (presCtrl.text.trim().isNotEmpty)
                              'presentacion': presCtrl.text.trim(),
                            'porcentaje': 70,
                          };
                          if (isEdit) {
                            await _repo.update(med.id, payload);
                          } else {
                            await _repo.create(payload);
                          }
                          if (ctx.mounted) Navigator.pop(ctx);
                          _snack(
                            isEdit ? 'Medicamento actualizado' : 'Medicamento creado',
                            ok: true,
                          );
                          _load(search: _query.isEmpty ? null : _query);
                        } catch (e) {
                          setS(() => saving = false);
                          _snack(e.toString().replaceFirst('Exception: ', ''));
                        }
                      },
                    ),
                ]),
              ),

              Container(height: 1, color: Colors.white.withValues(alpha: 0.07)),


              SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: formKey,
                  child: Column(children: [
                    TextFormField(
                      controller: nameCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: input('Nombre comercial', required: true),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: princCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: input('Principio activo'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: labCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: input('Laboratorio'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: presCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: input('Presentación (ej: comprimidos 500 mg)'),
                    ),
                    const SizedBox(height: 4),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

 
  Future<void> _confirmDelete(Medication med) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _border),
        ),
        title: const Text('Eliminar medicamento',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w300, fontSize: 16)),
        content: RichText(
          text: TextSpan(
            style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 14, height: 1.5),
            children: [
              const TextSpan(text: '¿Eliminar '),
              TextSpan(text: med.name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              const TextSpan(text: ' del catálogo? Esta acción no se puede deshacer.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.45))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar',
                style: TextStyle(color: Color(0xFFC62828), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (ok != true) return;
    try {
      await _repo.delete(med.id);
      _snack('Medicamento eliminado', ok: true);
      _load(search: _query.isEmpty ? null : _query);
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          color: Colors.white,
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Medicamentos',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w300,
                fontSize: 20, letterSpacing: 0.5)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 22),
            tooltip: 'Nuevo medicamento',
            onPressed: () => _showForm(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(children: [


        Container(
          color: _surface,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            cursorColor: Colors.white54,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, principio activo…',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.30), fontSize: 14),
              prefixIcon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.40), size: 20),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.close, color: Colors.white.withValues(alpha: 0.40), size: 18),
                      onPressed: () { _searchCtrl.clear(); },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.07),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),


        Expanded(child: _buildBody()),
      ]),


      floatingActionButton: FloatingActionButton(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        onPressed: () => _showForm(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white38, strokeWidth: 1.5),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.error_outline, color: Colors.white.withValues(alpha: 0.40), size: 40),
          const SizedBox(height: 12),
          Text(_error!,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 13),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _load,
            child: const Text('Reintentar', style: TextStyle(color: Colors.white)),
          ),
        ]),
      );
    }

    if (_meds.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.medication_outlined,
              color: Colors.white.withValues(alpha: 0.25), size: 52),
          const SizedBox(height: 14),
          Text(
            _query.isNotEmpty
                ? 'Sin resultados para "$_query"'
                : 'No hay medicamentos en el catálogo',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (_query.isEmpty)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Agregar el primero'),
              onPressed: () => _showForm(),
            ),
        ]),
      );
    }

    return RefreshIndicator(
      color: Colors.white,
      backgroundColor: _accent,
      onRefresh: () => _load(search: _query.isEmpty ? null : _query),
      child: ListView.separated(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: _meds.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _MedCard(
          med: _meds[i],
          onEdit: () => _showForm(med: _meds[i]),
          onDelete: () => _confirmDelete(_meds[i]),
        ),
      ),
    );
  }
}


class _MedCard extends StatelessWidget {
  final Medication med;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MedCard({
    required this.med,
    required this.onEdit,
    required this.onDelete,
  });

  static const _card = Color(0xFF3A0B32);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onEdit,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          ),
          child: Row(children: [

            // ícono
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
              child: Icon(Icons.medication_outlined,
                  color: Colors.white.withValues(alpha: 0.55), size: 20),
            ),

            const SizedBox(width: 12),

            // datos
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(med.name,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                if (med.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(med.subtitle,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45), fontSize: 12),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
                if (med.laboratory != null && med.laboratory!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(med.laboratory!,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.30), fontSize: 11),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ]),
            ),

            // acciones
            Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                icon: Icon(Icons.edit_outlined,
                    size: 18, color: Colors.white.withValues(alpha: 0.50)),
                tooltip: 'Editar',
                onPressed: onEdit,
              ),
              IconButton(
                icon: Icon(Icons.delete_outline,
                    size: 18, color: Colors.white.withValues(alpha: 0.35)),
                tooltip: 'Eliminar',
                onPressed: onDelete,
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}