import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/app_settings_repository.dart';
import '../../../../shared/widgets/app_panel.dart';
import '../../../../shared/widgets/app_select_field.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/download_result_snackbar.dart';
import '../../../../core/services/module_data_export_service.dart';
import '../../../../core/services/module_data_import_service.dart';
import '../../../../core/models/module_export_models.dart';
import '../../data/repositories/investment_repository.dart';
import '../../domain/models/investment_models.dart';
import '../blocs/broker/broker_bloc.dart';
import '../blocs/investment/investment_bloc.dart';

class InvestmentSettingsPage extends StatefulWidget {
  const InvestmentSettingsPage({super.key});

  @override
  State<InvestmentSettingsPage> createState() => _InvestmentSettingsPageState();
}

class _InvestmentSettingsPageState extends State<InvestmentSettingsPage> {
  // Export Settings
  String _selectedRangeOption = 'All';
  String _selectedFormatOption = 'PDF';
  DateTimeRange? _customExportRange;
  bool _isExporting = false;

  // Import Settings
  bool _isDownloadingSample = false;
  bool _isImporting = false;

  // Preferences
  int? _defaultBrokerId;

  // Expandable settings states
  bool _showAllCategories = false;
  bool _showAllBrokers = false;

  // Broker creation/editing states
  bool _isCreatingBroker = false;
  TaxProfile? _editingBrokerProfile;
  final _brokerFormKey = GlobalKey<FormState>();

  // Broker form controllers
  final _brokerNameController = TextEditingController();
  final _sttBuyController = TextEditingController();
  final _sttSellController = TextEditingController();
  final _exchangeController = TextEditingController();
  final _sebiController = TextEditingController();
  final _stampDutyController = TextEditingController();
  final _gstController = TextEditingController();
  final _brokeragePctController = TextEditingController();
  final _brokerageFlatController = TextEditingController();
  bool _brokerageMinOfBoth = false;
  final _dpChargeController = TextEditingController();
  double _estimatedCharges = 0.0;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    context.read<BrokerBloc>().add(const BrokersSubscriptionRequested());

    // Add listeners to update live preview
    _sttBuyController.addListener(_updateEstimate);
    _sttSellController.addListener(_updateEstimate);
    _exchangeController.addListener(_updateEstimate);
    _sebiController.addListener(_updateEstimate);
    _stampDutyController.addListener(_updateEstimate);
    _gstController.addListener(_updateEstimate);
    _brokeragePctController.addListener(_updateEstimate);
    _brokerageFlatController.addListener(_updateEstimate);
    _dpChargeController.addListener(_updateEstimate);
  }

  @override
  void dispose() {
    _brokerNameController.dispose();
    _sttBuyController.dispose();
    _sttSellController.dispose();
    _exchangeController.dispose();
    _sebiController.dispose();
    _stampDutyController.dispose();
    _gstController.dispose();
    _brokeragePctController.dispose();
    _brokerageFlatController.dispose();
    _dpChargeController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final settingsRepo = context.read<AppSettingsRepository>();
    final repo = context.read<InvestmentRepository>();
    final settings = await settingsRepo.getSettings();
    final brokers = await repo.getTaxProfiles();

    int? savedBrokerId = settings.selectedInvestmentBrokerId;
    // Validate saved broker still exists.
    if (savedBrokerId != null && !brokers.any((b) => b.id == savedBrokerId)) {
      savedBrokerId = null;
    }

    setState(() {
      _defaultBrokerId = savedBrokerId;
    });
  }

  void _initBrokerControllers(TaxProfile? profile) {
    if (profile == null) {
      _brokerNameController.text = '';
      _sttBuyController.text = '0.1';
      _sttSellController.text = '0.1';
      _exchangeController.text = '0.00345';
      _sebiController.text = '0.0001';
      _stampDutyController.text = '0.015';
      _gstController.text = '18';
      _brokeragePctController.text = '0.03';
      _brokerageFlatController.text = '20.0';
      _brokerageMinOfBoth = true;
      _dpChargeController.text = '15.93';
    } else {
      _brokerNameController.text = profile.brokerName;
      _sttBuyController.text = (profile.sttBuyPct * 100).toString();
      _sttSellController.text = (profile.sttSellPct * 100).toString();
      _exchangeController.text = (profile.exchangeChargePct * 100).toString();
      _sebiController.text = (profile.sebiChargePct * 100).toString();
      _stampDutyController.text = (profile.stampDutyPct * 100).toString();
      _gstController.text = (profile.gstPct * 100).toString();
      _brokeragePctController.text = (profile.brokeragePct * 100).toString();
      _brokerageFlatController.text = profile.brokerageFlat.toString();
      _brokerageMinOfBoth = profile.brokerageMinOfBoth;
      _dpChargeController.text = profile.dpChargePerScrip.toString();
    }
    _updateEstimate();
  }

  void _updateEstimate() {
    final sttBuy = double.tryParse(_sttBuyController.text) ?? 0.0;
    final sttSell = double.tryParse(_sttSellController.text) ?? 0.0;
    final exchange = double.tryParse(_exchangeController.text) ?? 0.0;
    final sebi = double.tryParse(_sebiController.text) ?? 0.0;
    final stamp = double.tryParse(_stampDutyController.text) ?? 0.0;
    final gst = double.tryParse(_gstController.text) ?? 0.0;
    final brokPct = double.tryParse(_brokeragePctController.text) ?? 0.0;
    final brokFlat = double.tryParse(_brokerageFlatController.text) ?? 0.0;
    final dp = double.tryParse(_dpChargeController.text) ?? 0.0;

    setState(() {
      _estimatedCharges = InvestmentRepository.calculateLiveTax(
        sttBuyPct: sttBuy / 100.0,
        sttSellPct: sttSell / 100.0,
        exchangeChargePct: exchange / 100.0,
        sebiChargePct: sebi / 100.0,
        stampDutyPct: stamp / 100.0,
        gstPct: gst / 100.0,
        brokeragePct: brokPct / 100.0,
        brokerageFlat: brokFlat,
        brokerageMinOfBoth: _brokerageMinOfBoth,
        dpChargePerScrip: dp,
        buyAmt: 100000.0,
        sellAmt: 105000.0,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repository = context.read<InvestmentRepository>();

    if (_isCreatingBroker || _editingBrokerProfile != null) {
      return _buildBrokerFormView(theme);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Investment Settings'),
      ),
      body: BlocBuilder<BrokerBloc, BrokerState>(
        builder: (context, brokerState) {
          return StreamBuilder<List<InvestmentCategory>>(
            stream: repository.watchCategories(),
            builder: (context, snapshot) {
              final categories = snapshot.data ?? const <InvestmentCategory>[];
              final brokers = brokerState.profiles;
              final visibleCategories = _showAllCategories ? categories : const <InvestmentCategory>[];
              final visibleBrokers = _showAllBrokers ? brokers : const <TaxProfile>[];

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: <Widget>[
                  // Section: Investment Export
                  AppPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Investment Export', style: theme.textTheme.titleLarge),
                        const SizedBox(height: 16),
                        AppSelectField<String>(
                          label: 'Time Range',
                          value: _selectedRangeOption,
                          options: const [
                            AppSelectOption(value: 'All', label: 'All Time'),
                            AppSelectOption(value: 'Month', label: 'This Month'),
                            AppSelectOption(value: 'Year', label: 'This Year'),
                            AppSelectOption(value: 'Custom', label: 'Custom Range...'),
                          ],
                          onChanged: (value) async {
                            if (value == 'Custom') {
                              final picked = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) {
                                setState(() {
                                  _customExportRange = DateTimeRange(start: picked.start, end: picked.end);
                                  _selectedRangeOption = value;
                                });
                              }
                            } else {
                              setState(() {
                                _selectedRangeOption = value;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        AppSelectField<String>(
                          label: 'Format',
                          value: _selectedFormatOption,
                          options: const [
                            AppSelectOption(value: 'PDF', label: 'PDF Report'),
                            AppSelectOption(value: 'Excel', label: 'Excel Sheet'),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedFormatOption = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _isExporting ? null : _handleExport,
                          icon: const Icon(Icons.download_rounded),
                          label: Text(_isExporting ? 'Exporting...' : 'Download $_selectedFormatOption'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Section: Investment Import
                  AppPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Investment Import', style: theme.textTheme.titleLarge),
                        const SizedBox(height: 6),
                        Text(
                          'Download a sample Excel file, fill it row by row, then import it. Nothing is saved unless every filled row is valid.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: <Widget>[
                            OutlinedButton.icon(
                              onPressed: _isDownloadingSample || _isImporting ? null : _downloadSampleExcel,
                              icon: const Icon(Icons.download_rounded),
                              label: Text(_isDownloadingSample ? 'Preparing...' : 'Download Sample Excel'),
                            ),
                            FilledButton.icon(
                              onPressed: _isDownloadingSample || _isImporting ? null : _importExcel,
                              icon: const Icon(Icons.upload_file_rounded),
                              label: Text(_isImporting ? 'Importing...' : 'Import Excel'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Section: Investment Settings (Categories and Brokers CRUD)
                  AppPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Investment Settings', style: theme.textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text(
                          'Manage investment categories and broker profiles.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('Categories', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: categories.isEmpty
                                    ? const SizedBox.shrink()
                                    : FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: TextButton(
                                          onPressed: () {
                                            setState(() {
                                              _showAllCategories = !_showAllCategories;
                                            });
                                          },
                                          child: Text(
                                            _showAllCategories ? 'Hide category' : 'View category',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: FilledButton.tonalIcon(
                                    onPressed: () => _showCategoryDialog(context, existingCategories: categories),
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add category', overflow: TextOverflow.ellipsis),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (categories.isEmpty)
                          _buildEmptyCard(context, 'No categories added yet.')
                        else
                          ...visibleCategories.map(
                            (category) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildCategoryCard(
                                context,
                                category: category,
                                canDelete: categories.length > 1,
                                existingCategories: categories,
                              ),
                            ),
                          ),
                        const SizedBox(height: 6),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text('Broker Profiles', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: brokers.isEmpty
                                    ? const SizedBox.shrink()
                                    : FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: TextButton(
                                          onPressed: () {
                                            setState(() {
                                              _showAllBrokers = !_showAllBrokers;
                                            });
                                          },
                                          child: Text(
                                            _showAllBrokers ? 'Hide Broker' : 'View Broker',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: FilledButton.tonalIcon(
                                    onPressed: () {
                                      setState(() {
                                          _isCreatingBroker = true;
                                          _initBrokerControllers(null);
                                      });
                                    },
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add broker', overflow: TextOverflow.ellipsis),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (brokers.isEmpty)
                          _buildEmptyCard(context, 'No broker profiles added yet.')
                        else
                          ...visibleBrokers.map(
                            (broker) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildBrokerCard(
                                context,
                                broker: broker,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Section: Preferences
                  AppPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Preferences', style: theme.textTheme.titleLarge),
                        const SizedBox(height: 16),
                        AppSelectField<int?>(
                          label: 'Default Broker',
                          value: _defaultBrokerId,
                          options: [
                            const AppSelectOption(value: null, label: 'Select default broker'),
                            ...brokers.map(
                              (b) => AppSelectOption<int?>(value: b.id, label: b.brokerName),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _defaultBrokerId = value;
                            });
                            context.read<AppSettingsRepository>()
                                .updateSelectedInvestmentBrokerId(value);
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section: Delete Investment Data
                  AppPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Delete Investment Data', style: theme.textTheme.titleLarge),
                        const SizedBox(height: 6),
                        Text(
                          'This clears all investment entries, sell records, and resets broker profiles and categories to defaults.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.tonalIcon(
                          style: FilledButton.styleFrom(
                            foregroundColor: theme.colorScheme.error,
                          ),
                          onPressed: () => _confirmDeleteAllData(context),
                          icon: const Icon(Icons.delete_forever_rounded),
                          label: const Text('Delete Data'),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyCard(BuildContext context, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(message),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required InvestmentCategory category,
    required bool canDelete,
    required List<InvestmentCategory> existingCategories,
  }) {
    final theme = Theme.of(context);
    final color = Color(category.colorValue);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.14),
            child: Icon(
              AppConstants.categoryIconFromCodePoint(category.iconCodePoint),
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(category.name, style: theme.textTheme.titleMedium),
          ),
          IconButton(
            onPressed: () => _showCategoryDialog(
              context,
              category: category,
              existingCategories: existingCategories,
            ),
            icon: const Icon(Icons.edit_rounded),
          ),
          IconButton(
            onPressed: canDelete
                ? () => _handleDeleteCategory(context, category, existingCategories)
                : null,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildBrokerCard(
    BuildContext context, {
    required TaxProfile broker,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: <Widget>[
          const CircleAvatar(
            child: Icon(Icons.business_rounded),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(broker.brokerName, style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  'Brokerage: ${broker.brokerageMinOfBoth ? 'Min' : 'Flat'} (${(broker.brokeragePct * 100).toStringAsFixed(2)}% / ${broker.brokerageFlat})',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _editingBrokerProfile = broker;
                _initBrokerControllers(broker);
              });
            },
            icon: const Icon(Icons.edit_rounded),
          ),
          IconButton(
            onPressed: () => _handleDeleteBroker(context, broker),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildBrokerFormView(ThemeData theme) {
    final isEdit = _editingBrokerProfile != null;
    final title = isEdit ? 'Edit Broker' : 'Add Broker';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            setState(() {
              _isCreatingBroker = false;
              _editingBrokerProfile = null;
            });
          },
        ),
      ),
      body: Form(
        key: _brokerFormKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: <Widget>[
            AppPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _brokerNameController,
                    decoration: const InputDecoration(
                      labelText: 'Broker Name',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Broker name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _sttBuyController,
                          decoration: const InputDecoration(
                            labelText: 'STT Buy %',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _sttSellController,
                          decoration: const InputDecoration(
                            labelText: 'STT Sell %',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _exchangeController,
                          decoration: const InputDecoration(
                            labelText: 'Exchange Charge %',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _sebiController,
                          decoration: const InputDecoration(
                            labelText: 'SEBI Charge %',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _stampDutyController,
                          decoration: const InputDecoration(
                            labelText: 'Stamp Duty %',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _gstController,
                          decoration: const InputDecoration(
                            labelText: 'GST %',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _brokeragePctController,
                          decoration: const InputDecoration(
                            labelText: 'Brokerage %',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _brokerageFlatController,
                          decoration: const InputDecoration(
                            labelText: 'Brokerage Flat',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Brokerage is Min of both (Flat vs Pct)'),
                    value: _brokerageMinOfBoth,
                    onChanged: (val) {
                      setState(() {
                        _brokerageMinOfBoth = val;
                        _updateEstimate();
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _dpChargeController,
                    decoration: const InputDecoration(
                      labelText: 'DP Charge per Scrip',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Live Estimate Preview',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Estimated charges on 1,00,000 buy + 1,05,000 sell = ${_estimatedCharges.toStringAsFixed(2)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saveBrokerProfile,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(isEdit ? 'Update Broker' : 'Save Broker'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveBrokerProfile() {
    if (!_brokerFormKey.currentState!.validate()) {
      return;
    }

    final sttBuy = double.tryParse(_sttBuyController.text) ?? 0.0;
    final sttSell = double.tryParse(_sttSellController.text) ?? 0.0;
    final exchange = double.tryParse(_exchangeController.text) ?? 0.0;
    final sebi = double.tryParse(_sebiController.text) ?? 0.0;
    final stamp = double.tryParse(_stampDutyController.text) ?? 0.0;
    final gst = double.tryParse(_gstController.text) ?? 0.0;
    final brokPct = double.tryParse(_brokeragePctController.text) ?? 0.0;
    final brokFlat = double.tryParse(_brokerageFlatController.text) ?? 0.0;
    final dp = double.tryParse(_dpChargeController.text) ?? 0.0;

    final profile = TaxProfile(
      id: _editingBrokerProfile?.id ?? 0,
      brokerName: _brokerNameController.text.trim(),
      sttBuyPct: sttBuy / 100.0,
      sttSellPct: sttSell / 100.0,
      exchangeChargePct: exchange / 100.0,
      sebiChargePct: sebi / 100.0,
      stampDutyPct: stamp / 100.0,
      gstPct: gst / 100.0,
      brokeragePct: brokPct / 100.0,
      brokerageFlat: brokFlat,
      brokerageMinOfBoth: _brokerageMinOfBoth,
      dpChargePerScrip: dp,
      createdAt: _editingBrokerProfile?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (_editingBrokerProfile != null) {
      context.read<BrokerBloc>().add(BrokerUpdated(profile));
    } else {
      context.read<BrokerBloc>().add(BrokerAdded(profile));
    }

    showAppSnackBar(
      context,
      message: 'Broker profile saved.',
      type: AppSnackBarType.info,
    );

    setState(() {
      _isCreatingBroker = false;
      _editingBrokerProfile = null;
    });
  }

  Future<void> _handleDeleteBroker(BuildContext context, TaxProfile profile) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Broker Profile'),
          content: Text('Are you sure you want to delete "${profile.brokerName}"? This resets linked entries to no broker.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true && context.mounted) {
      context.read<BrokerBloc>().add(BrokerDeleted(profile.id));
      showAppSnackBar(
        context,
        message: 'Broker profile deleted.',
        type: AppSnackBarType.info,
      );
    }
  }

  Future<void> _handleDeleteCategory(
    BuildContext context,
    InvestmentCategory category,
    List<InvestmentCategory> allCategories,
  ) async {
    final repository = context.read<InvestmentRepository>();
    final entries = await repository.getBuyEntries();
    final linkedCount = entries.where((e) => e.categoryId == category.id).length;

    if (!context.mounted) return;

    if (linkedCount > 0) {
      final otherCategories = allCategories.where((c) => c.id != category.id).toList();
      int? selectedCategoryId = otherCategories.isNotEmpty ? otherCategories.first.id : null;

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Reassign Entries'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$linkedCount entries use this category. Reassign to another category first.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    AppSelectField<int?>(
                      label: 'Reassign to',
                      value: selectedCategoryId,
                      options: otherCategories.map((c) {
                        return AppSelectOption<int?>(
                          value: c.id,
                          label: c.name,
                        );
                      }).toList(),
                      onChanged: (val) {
                        setDialogState(() {
                          selectedCategoryId = val;
                        });
                      },
                    ),
                  ],
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: selectedCategoryId == null
                        ? null
                        : () async {
                            final scaffoldMessenger = ScaffoldMessenger.of(context);
                            await repository.deleteCategory(
                              category.id,
                              reassignCategoryId: selectedCategoryId,
                            );
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                            if (context.mounted) {
                              scaffoldMessenger.showSnackBar(
                                buildAppSnackBar(
                                  context,
                                  message: 'Category deleted and entries reassigned.',
                                  type: AppSnackBarType.info,
                                ),
                              );
                            }
                          },
                    child: const Text('Reassign & Delete'),
                  ),
                ],
              );
            },
          );
        },
      );
    } else {
      final shouldDelete = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Delete Category'),
            content: Text('Are you sure you want to delete category "${category.name}"?'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Delete'),
              ),
            ],
          );
        },
      );

      if (shouldDelete == true && context.mounted) {
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        await repository.deleteCategory(category.id);
        if (context.mounted) {
          scaffoldMessenger.showSnackBar(
            buildAppSnackBar(
              context,
              message: 'Category deleted.',
              type: AppSnackBarType.info,
            ),
          );
        }
      }
    }
  }

  Future<void> _showCategoryDialog(
    BuildContext context, {
    InvestmentCategory? category,
    required List<InvestmentCategory> existingCategories,
  }) async {
    final repository = context.read<InvestmentRepository>();
    final nameController = TextEditingController(text: category?.name ?? '');
    var selectedIcon = category == null
        ? AppConstants.categoryIconChoices.first
        : AppConstants.categoryIconFromCodePoint(category.iconCodePoint);
    var selectedColor =
        category?.colorValue ?? AppConstants.categoryColorChoices.first;

    if (!AppConstants.categoryIconChoices.contains(selectedIcon)) {
      selectedIcon = AppConstants.categoryIconChoices.first;
    }
    if (!AppConstants.categoryColorChoices.contains(selectedColor)) {
      selectedColor = AppConstants.categoryColorChoices.first;
    }

    final categoriesList = existingCategories.isEmpty
        ? await repository.getCategories()
        : existingCategories;

    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    category == null ? 'Add Category' : 'Edit Category',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Category name',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Choose an icon',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: AppConstants.categoryIconChoices
                        .map((icon) {
                          final selected = icon == selectedIcon;
                          return InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () =>
                                setSheetState(() => selectedIcon = icon),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: selected
                                    ? Theme.of(context).colorScheme.primaryContainer
                                    : Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(icon),
                            ),
                          );
                        })
                        .toList(growable: false),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Choose a color',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: AppConstants.categoryColorChoices
                        .map((colorValue) {
                          final selected = colorValue == selectedColor;
                          return InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () =>
                                setSheetState(() => selectedColor = colorValue),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: Color(colorValue),
                                shape: BoxShape.circle,
                                border: selected
                                    ? Border.all(
                                        color: Theme.of(context).colorScheme.onSurface,
                                        width: 2,
                                      )
                                    : null,
                              ),
                            ),
                          );
                        })
                        .toList(growable: false),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        final trimmedName = nameController.text.trim();
                        if (trimmedName.isEmpty) {
                          return;
                        }

                        final hasDuplicate = categoriesList.any(
                          (existingCategory) =>
                              existingCategory.id != category?.id &&
                              existingCategory.name.toLowerCase() ==
                                  trimmedName.toLowerCase(),
                        );
                        if (hasDuplicate) {
                          showAppSnackBar(
                            context,
                            message: 'Category already exists.',
                            type: AppSnackBarType.warning,
                          );
                          return;
                        }

                        if (category == null) {
                          await repository.insertCategory(
                            name: trimmedName,
                            colorValue: selectedColor,
                            iconCodePoint: selectedIcon.codePoint,
                          );
                        } else {
                          await repository.updateCategory(
                            id: category.id,
                            name: trimmedName,
                            colorValue: selectedColor,
                            iconCodePoint: selectedIcon.codePoint,
                          );
                        }

                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Text(
                          category == null
                              ? 'Save Category'
                              : 'Update Category',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleExport() async {
    setState(() {
      _isExporting = true;
    });

    try {
      DateTimeRange? range;
      final now = DateTime.now();
      if (_selectedRangeOption == 'Month') {
        range = DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
        );
      } else if (_selectedRangeOption == 'Year') {
        range = DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: DateTime(now.year, 12, 31, 23, 59, 59),
        );
      } else if (_selectedRangeOption == 'Custom') {
        range = _customExportRange;
      }

      final format = _selectedFormatOption == 'PDF' ? ModuleExportFormat.pdf : ModuleExportFormat.excel;
      final path = await context.read<ModuleDataExportService>().exportInvestmentData(
            range: range,
            format: format,
          );

      if (!mounted) return;
      showDownloadResultSnackBar(
        context,
        message: 'Investment data exported successfully to $path',
        path: path,
      );
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: 'Export failed: ${e.toString()}',
        type: AppSnackBarType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Future<void> _downloadSampleExcel() async {
    setState(() {
      _isDownloadingSample = true;
    });

    try {
      final path = await context.read<ModuleDataImportService>().downloadInvestmentSampleExcel();
      if (!mounted) return;
      showDownloadResultSnackBar(
        context,
        message: 'Sample format downloaded successfully to $path',
        path: path,
      );
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: 'Download failed: ${e.toString()}',
        type: AppSnackBarType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDownloadingSample = false;
        });
      }
    }
  }

  Future<void> _importExcel() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select Investment Excel File',
      type: FileType.custom,
      allowedExtensions: const ['xlsx'],
    );

    if (result == null || result.files.single.path == null || !mounted) {
      return;
    }

    setState(() {
      _isImporting = true;
    });

    if (!mounted) return;
    try {
      final previewData = await context.read<ModuleDataImportService>().importInvestmentExcel(result.files.single.path!);
      if (!mounted) return;
      
      Navigator.of(context).pushNamed(
        AppRoutes.investmentImportPreview,
        arguments: InvestmentImportPreviewArgs(previewData: previewData),
      );
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: 'Import failed: ${e.toString()}',
        type: AppSnackBarType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  Future<void> _confirmDeleteAllData(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete All Investment Data'),
          content: const Text('This will delete all investment entries, sell history, and reset settings. Are you sure?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true && context.mounted) {
      final repo = context.read<InvestmentRepository>();
      await repo.clearSectionData();
      if (context.mounted) {
        showAppSnackBar(
          context,
          message: 'All investment data deleted.',
          type: AppSnackBarType.info,
        );
        context.read<InvestmentBloc>().add(const InvestmentSubscriptionRequested());
      }
    }
  }
}
