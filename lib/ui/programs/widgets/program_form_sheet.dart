import "package:flutter/material.dart";
import "package:workout_tracker/config/dependencies.dart";
import "package:workout_tracker/data/repositories/program_repository.dart";

class ProgramFormSheet extends StatefulWidget {
  const ProgramFormSheet({super.key, this.programId, this.initialName});

  final int? programId;
  final String? initialName;

  @override
  State<ProgramFormSheet> createState() => _ProgramFormSheetState();
}

class _ProgramFormSheetState extends State<ProgramFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final repository = getIt<ProgramRepository>();

    try {
      if (widget.programId != null) {
        await repository.updateProgram(
          id: widget.programId!,
          name: _nameController.text,
        );
      } else {
        await repository.createProgram(name: _nameController.text);
      }
      if (!mounted) {
        return;
      }
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst("Exception: ", "")),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + keyboardInset),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.programId != null ? "Edit program" : "Add program",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: "Program name"),
              validator: (value) {
                final trimmed = (value ?? "").trim();
                if (trimmed.isEmpty) {
                  return "Program name is required";
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : FilledButton(onPressed: _submit, child: const Text("Save")),
            ),
          ],
        ),
      ),
    );
  }
}
