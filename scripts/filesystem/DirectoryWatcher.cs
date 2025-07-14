using Godot;
using Godot.Collections;
using System;
using System.IO;

public partial class DirectoryWatcher : Node
{

	[Export]
	public Array<string> WatchedExtensions = new Array<string>();

	private FileSystemWatcher _watcher;

	[Signal]
	public delegate void FileCreatedEventHandler(string path);
	[Signal]
	public delegate void FileChangedEventHandler(string path);
	[Signal]
	public delegate void FileDeletedEventHandler(string path);
	[Signal]
	public delegate void FileRenamedEventHandler(string oldPath, string newPath);

	public void StartWatching(string directory)
	{
		StopWatching();

		_watcher = new FileSystemWatcher(directory)
		{
			NotifyFilter = NotifyFilters.FileName | NotifyFilters.LastWrite | NotifyFilters.Size | NotifyFilters.DirectoryName,
			IncludeSubdirectories = true,
			EnableRaisingEvents = true
		};

		_watcher.Created += (s, e) => CallDeferred("emit_signal", SignalName.FileCreated, e.FullPath);
		_watcher.Changed += (s, e) => CallDeferred("emit_signal", SignalName.FileChanged, e.FullPath);
		_watcher.Deleted += (s, e) => CallDeferred("emit_signal", SignalName.FileDeleted, e.FullPath);
		_watcher.Renamed += (s, e) => CallDeferred("emit_signal", SignalName.FileRenamed, e.OldFullPath, e.FullPath);
	}

	public void StopWatching()
	{
		if (_watcher != null)
		{
			_watcher.EnableRaisingEvents = false;
			_watcher.Dispose();
			_watcher = null;
		}
	}

	public override void _ExitTree()
	{
		StopWatching();

		base._ExitTree();
	}
}
