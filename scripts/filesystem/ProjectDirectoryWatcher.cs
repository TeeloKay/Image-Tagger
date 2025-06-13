using Godot;
using System;
using System.Diagnostics;
using System.IO;

public partial class ProjectDirectoryWatcher : Node
{
	[Export]
	public string WatchedPath = "";

	private FileSystemWatcher _watcher;

	[Signal]
	public delegate void FileCreatedEventHandler(string path);

	[Signal]
	public delegate void FileDeletedEventHandler(string path);

	[Signal]
	public delegate void FileRenamedEventHandler(string oldpath, string newPath);

	[Signal]
	public delegate void FileChangedEventHandler(string path);

	// Called when the node enters the scene tree for the first time.
	public override void _Ready() { }


	public void WatchPath(string path)
	{
		StopWatchingPath();

		_watcher = new FileSystemWatcher(path)
		{
			IncludeSubdirectories = true,
			NotifyFilter = NotifyFilters.FileName | NotifyFilters.DirectoryName | NotifyFilters.LastWrite
		};

		_watcher.EnableRaisingEvents = true;

		_watcher.Created += OnFileCreated;
		_watcher.Deleted += OnFileDeleted;
		_watcher.Renamed += OnFileRenamed;
		_watcher.Changed += OnFileChanged;
	}

	public override void _ExitTree()
	{
		base._ExitTree();
		StopWatchingPath();
	}

	private void StopWatchingPath()
	{
		if (_watcher != null)
		{
			_watcher.EnableRaisingEvents = false;
			_watcher.Dispose();
		}
	}
	private void OnFileCreated(Object sender, FileSystemEventArgs args)
	{
		EmitSignal(SignalName.FileCreated, args.FullPath);
	}

	private void OnFileDeleted(Object sender, FileSystemEventArgs args)
	{
		EmitSignal(SignalName.FileDeleted, args.FullPath);
	}

	private void OnFileRenamed(Object sender, RenamedEventArgs args)
	{
		EmitSignal(SignalName.FileRenamed, args.OldFullPath, args.FullPath);
	}

	private void OnFileChanged(Object sender, FileSystemEventArgs args)
	{
		EmitSignal(SignalName.FileChanged, args.FullPath);
	}
}
