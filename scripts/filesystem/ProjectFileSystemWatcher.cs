using Godot;
using System;
using System.IO;

public partial class ProjectFileSystemWatcher : Node
{
	private FileSystemWatcher _watcher;

	[Export(PropertyHint.GlobalDir)] public string WatchDirectory { get; set; } = "";
	[Export] string Filter { get; set; } = "*.*";
	[Export] public bool IncludeSubdirectories { get; set; } = true;

	[Signal] public delegate void WatchStartedEventHandler(string path);
	[Signal] public delegate void WatchStoppedEventHandler();
	[Signal] public delegate void FileCreatedEventHandler(string path);
	[Signal] public delegate void FileChangedEventHandler(string path);
	[Signal] public delegate void FileDeletedEventHandler(string path);
	[Signal] public delegate void FileRenamedEventHandler(string oldPath, string newPath);
	[Signal] public delegate void FileWatcherErrorEventHandler(string message);

	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
		if (!string.IsNullOrEmpty(WatchDirectory) && Directory.Exists(WatchDirectory))
		{
			StartWatching(WatchDirectory);
		}
	}

	public void StartWatching(string directory)
	{
		StopWatching();
		if (!Directory.Exists(directory)) return;
		WatchDirectory = directory;
		_watcher = new FileSystemWatcher(directory)
		{
			Filter = Filter,
			IncludeSubdirectories = IncludeSubdirectories,
			NotifyFilter = NotifyFilters.FileName |
						   NotifyFilters.LastWrite |
						   NotifyFilters.CreationTime
		};

		_watcher.Created += OnCreated;
		_watcher.Changed += OnChanged;
		_watcher.Deleted += OnDeleted;
		_watcher.Renamed += OnRenamed;
		_watcher.Error += OnError;

		_watcher.EnableRaisingEvents = true;
		EmitSignal(SignalName.WatchStarted, WatchDirectory);
	}

	private void OnCreated(object sender, FileSystemEventArgs e)
	{
		if (File.Exists(e.FullPath))
			Callable.From(() => EmitSignal(SignalName.FileCreated, e.FullPath)).CallDeferred();
	}

	private void OnChanged(object sender, FileSystemEventArgs e)
	{
		if (File.Exists(e.FullPath))
			Callable.From(() => EmitSignal(SignalName.FileChanged, e.FullPath)).CallDeferred();
	}

	private void OnDeleted(object sender, FileSystemEventArgs e)
	{
		Callable.From(() => EmitSignal(SignalName.FileDeleted, e.FullPath)).CallDeferred();
	}

	private void OnRenamed(object sender, RenamedEventArgs e)
	{
		if (File.Exists(e.FullPath))
			Callable.From(() => EmitSignal(SignalName.FileRenamed, e.OldFullPath, e.FullPath)).CallDeferred();
	}

	private void OnError(object sender, ErrorEventArgs e)
	{
		Callable.From(() => EmitSignal(SignalName.FileWatcherError, e.GetException().ToString())).CallDeferred();
	}


	public void StopWatching()
	{
		if (_watcher == null)
			return;

		_watcher.EnableRaisingEvents = false;

		_watcher.Created -= OnCreated;
		_watcher.Changed -= OnChanged;
		_watcher.Deleted -= OnDeleted;
		_watcher.Renamed -= OnRenamed;
		_watcher.Error -= OnError;

		_watcher.Dispose();
		_watcher = null;

		EmitSignal(SignalName.WatchStopped);
	}

	public override void _ExitTree()
	{
		StopWatching();
	}
}
