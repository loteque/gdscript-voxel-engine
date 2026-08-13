class_name RuntimeWorkloadEvidenceExporter
extends RefCounted

const FILENAME := "runtime-workload-isolation-evidence.json"


static func export_payload(payload: Dictionary) -> void:
	var json := JSON.stringify(payload, "  ")
	if OS.has_feature("web"):
		var encoded := Marshalls.utf8_to_base64(json)
		JavaScriptBridge.eval("""
			(() => {
				const binary = atob('%s');
				const bytes = Uint8Array.from(binary, c => c.charCodeAt(0));
				const blob = new Blob([bytes], {type: 'application/json'});
				const url = URL.createObjectURL(blob);
				const anchor = document.createElement('a');
				anchor.href = url;
				anchor.download = '%s';
				anchor.click();
				setTimeout(() => URL.revokeObjectURL(url), 1000);
			})();
		""" % [encoded, FILENAME])
		return
	var file := FileAccess.open("user://%s" % FILENAME, FileAccess.WRITE)
	if file != null:
		file.store_string(json)
