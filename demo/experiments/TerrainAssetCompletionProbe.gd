class_name TerrainAssetCompletionProbe
extends RefCounted

func take_loaded_asset(path: String) -> TerrainChunkAsset:
	return ResourceLoader.load_threaded_get(path) as TerrainChunkAsset
