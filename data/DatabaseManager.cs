using System;
using System.Collections.Generic;
using Godot;
using Godot.Collections;
using Microsoft.Data.Sqlite;

public partial class DatabaseManager : Node
{

	private const string SchemaVersionKey = "schema_version";
	private const string VersionSettingPath = "application/config/version:";

	readonly HashSet<string> AllowedTagFields = ["color"];
	readonly HashSet<string> AllowedImageFields = ["fingerprint", "path", "favorited", "metadata"];

	private SqliteConnection _connection;

	[Export(PropertyHint.GlobalFile)] private string _databasePath = "";

	public bool IsDataBaseOpen => _connection != null && _connection.State == System.Data.ConnectionState.Open;

	[Signal]
	public delegate void DatabaseOpenedEventHandler(string path);
	[Signal]
	public delegate void DatabaseClosedEventHandler();


	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{

	}

	public void SetDatabasePath(string databasePath)
	{
		if (_connection != null)
		{
			CloseDatabase();
		}
		_databasePath = databasePath;
		OpenDatabase();
	}

	public void OpenDatabase()
	{
		try
		{
			var absolutePath = ProjectSettings.GlobalizePath(_databasePath);
			_connection = new SqliteConnection($"Data source={absolutePath}");
			_connection.Open();
			InitializeSchema();
			EmitSignal(SignalName.DatabaseOpened, absolutePath);
			GD.Print("Opened SQLite database at ", absolutePath);
		}
		catch (Exception e)
		{
			GD.PushError("Failed to open database: ", e.Message);
		}
	}

	public void CloseDatabase()
	{
		_connection?.Close();
		_connection = null;
		EmitSignal(SignalName.DatabaseClosed);
	}

	private void InitializeSchema()
	{
		using var cmd = _connection.CreateCommand();
		cmd.CommandText = @"
		CREATE TABLE IF NOT EXISTS images (
		hash TEXT PRIMARY KEY,
		path TEXT NOT NULL,
		fingerprint TEXT NOT NULL,
		favorited INTEGER DEFAULT 0 NOT NULL,
		metadata TEXT
		);
		
		CREATE TABLE IF NOT EXISTS tags (
		name TEXT PRIMARY KEY,
		color TEXT
		);

		CREATE TABLE IF NOT EXISTS image_tags (
		tag TEXT,
		image_hash TEXT,
		PRIMARY KEY (tag, image_hash),
		FOREIGN KEY (tag) REFERENCES tags(name)
		FOREIGN KEY (image_hash) REFERENCES images(hash)
		);

		CREATE TABLE IF NOT EXISTS meta (
		key TEXT primary KEY,
		value TEXT
		);

		CREATE INDEX IF NOT EXISTS idx_image_path ON images(path);
		INSERT OR IGNORE INTO meta( key, value) VALUES ($key, $value)
		";
		cmd.Parameters.AddWithValue("$key", SchemaVersionKey);
		cmd.Parameters.AddWithValue("$value", ProjectSettings.GetSetting(VersionSettingPath).ToString());

		cmd.ExecuteNonQuery();
	}

	#region Image Operations
	public void AddImage(string hash, string path, string fingerprint, string metadataJson = "{}")
	{
		using var cmd = _connection.CreateCommand();
		cmd.CommandText = "INSERT OR REPLACE INTO images (hash, path, fingerprint, metadata) VALUES ($hash, $path, $fingerprint, $metadata);";
		cmd.Parameters.AddWithValue("$hash", hash);
		cmd.Parameters.AddWithValue("$path", path);
		cmd.Parameters.AddWithValue("$fingerprint", fingerprint);
		cmd.Parameters.AddWithValue("$metadata", metadataJson);
		cmd.ExecuteNonQuery();
	}

	public void DeleteImage(string hash)
	{
		using var cmd = _connection.CreateCommand();
		cmd.CommandText = @"
		DELETE FROM image_tags WHERE image_hash = $hash;
		DELETE FROM images where hash = $hash;
		";
		cmd.Parameters.AddWithValue("$hash", hash);
		cmd.ExecuteNonQuery();
	}

	public string GetHashForPath(string path)
	{
		using var cmd = _connection.CreateCommand();
		cmd.CommandText = @"SELECT hash FROM images where path = $path;";
		cmd.Parameters.AddWithValue($"path", path);
		using var reader = cmd.ExecuteReader();

		if (reader.Read())
		{
			return reader.GetString(0);
		}
		return "";
	}

	public void UpdateImageField(string hash, string field, Godot.Variant value)
	{
		if (!AllowedImageFields.Contains(field))
		{
			return;
		}

		using var cmd = _connection.CreateCommand();
		cmd.CommandText = $@"
		UPDATE images
		SET {field} = $value
		WHERE hash = $hash;
		";
		cmd.Parameters.AddWithValue("$value", value.ToString());
		cmd.Parameters.AddWithValue("$hash", hash);

		cmd.ExecuteNonQuery();
	}

	public void SetImageFavorited(string hash, bool favorited = true)
	{
		return;
		UpdateImageField(hash, "favorited", favorited);
	}

	public Dictionary GetImageInfo(string hash)
	{
		GD.Print(hash);
		var info = new Dictionary
		{
			{ "hash", hash }
		};

		using var cmd = _connection.CreateCommand();
		cmd.CommandText = @"
			SELECT path, fingerprint, favorited, metadata
			FROM images
			WHERE hash = $hash;
			";
		cmd.Parameters.AddWithValue("$hash", hash);

		using var reader = cmd.ExecuteReader();
		if (reader.Read())
		{
			info.Add("path", reader.GetString(0));
			info.Add("fingerprint", reader.GetString(1));
			info.Add("favorited", reader.GetInt32(2) != 0);
			info.Add("metadata", reader.IsDBNull(3) ? "{}" : reader.GetString(3));
		}
		return info;
	}

	public Array<Dictionary> GetAllImages()
	{
		var results = new Array<Dictionary>();
		using var cmd = _connection.CreateCommand();
		cmd.CommandText = "SELECT hash, path, fingerprint, metadata FROM images;";

		using var reader = cmd.ExecuteReader();
		while (reader.Read())
		{
			results.Add(new Dictionary
			{
				{"hash", reader.GetString(0)},
				{"path", reader.GetString(1)},
				{"fingerprint", reader.GetString(2)},
				{"metadata", reader.IsDBNull(3) ? "{}" : reader.GetString(3)}
			});
		}
		return results;
	}

	public Godot.Collections.Dictionary<string, string> UpdateImagePath(string imageHash, string newPath)
	{
		using var getCmd = _connection.CreateCommand();
		getCmd.CommandText = "SELECT path FROM images where hash = @hash;";
		getCmd.Parameters.AddWithValue("@hash", imageHash);

		string oldpath = "";
		using (var reader = getCmd.ExecuteReader())
		{
			if (reader.Read())
			{
				oldpath = reader.GetString(0);
			}
		}

		if (oldpath == null) return null;

		using var updateCmd = _connection.CreateCommand();
		updateCmd.CommandText = "UPDATE images SET path = @path WHERE hash = @hash;";
		updateCmd.Parameters.AddWithValue("@path", newPath);
		updateCmd.Parameters.AddWithValue("@hash", newPath);
		updateCmd.ExecuteNonQuery();

		return new Godot.Collections.Dictionary<string, string>
		{
			{"old_path", oldpath },
			{"new_path", newPath}
		};
	}
	#endregion
	#region Tag Operations

	public Error AddTag(StringName tag, string colorHex)
	{
		using var cmd = _connection.CreateCommand();
		cmd.CommandText = "INSERT OR IGNORE INTO tags (name, color) VALUES ($name, $color);";
		cmd.Parameters.AddWithValue("$name", tag.ToString());
		cmd.Parameters.AddWithValue("$color", colorHex);
		cmd.ExecuteNonQuery();
		return Error.Ok;
	}

	public Error DeleteTag(StringName tag)
	{
		using var cmd = _connection.CreateCommand();
		cmd.CommandText = @"
		DELETE FROM image_tags where tag = $tag;
		DELETE FROM tags where name = $tag;
		";
		cmd.Parameters.AddWithValue("$tag", tag.ToString());
		cmd.ExecuteNonQuery();
		return Error.Ok;
	}

	public void UpdateTagField(StringName tag, string field, Godot.Variant value)
	{
		if (!AllowedTagFields.Contains(field))
		{
			return;
		}

		using var cmd = _connection.CreateCommand();
		cmd.CommandText = $@"
		UPDATE tags
		SET {field} = $value
		WHERE name = $tag;
		";
		cmd.Parameters.AddWithValue("$value", value.ToString());
		cmd.Parameters.AddWithValue("$tag", tag.ToString());

		cmd.ExecuteNonQuery();
	}

	public int GetImageCountForTag(StringName tag)
	{
		using var cmd = _connection.CreateCommand();
		cmd.CommandText = @"
		SELECT COUNT(*)
		FROM image_tags
		where tag = $tag;
		";

		cmd.Parameters.AddWithValue("$tag", tag.ToString());

		var result = Convert.ToInt32(cmd.ExecuteScalar());
		return result;
	}

	public Godot.Collections.Dictionary<string, int> GetImageCountsPerTag()
	{
		var results = new Godot.Collections.Dictionary<string, int>();
		using var cmd = _connection.CreateCommand();

		cmd.CommandText = @"
		SELECT tags.name, COUNT(image_tags.image_hash) AS image_count
		FROM tags
		LEFT JOIN image_tags ON tags.name = image_tags.tag
		GROUP BY tags.name
		";

		using var reader = cmd.ExecuteReader();
		while (reader.Read())
		{
			results[reader.GetString(0)] = reader.GetInt32(1);
		}
		return results;
	}

	public Godot.Collections.Dictionary GetTagInfo(StringName tag)
	{
		var info = new Godot.Collections.Dictionary();

		using var cmd = _connection.CreateCommand();
		cmd.CommandText = @"
		SELECT name,color
		FROM tags
		WHERE name = $tag;
		";

		cmd.Parameters.AddWithValue("$tag", tag.ToString());
		using var reader = cmd.ExecuteReader();
		if (reader.Read())
		{
			return new Dictionary {
				{ "name", new StringName(reader.GetString(0)) },
				{ "color", reader.GetString(1) }
			};

		}

		return info;
	}

	public Array<Dictionary> GetAllTags()
	{
		var results = new Array<Dictionary>();
		using var cmd = _connection.CreateCommand();
		cmd.CommandText = "SELECT name, color FROM tags;";

		using var reader = cmd.ExecuteReader();
		while (reader.Read())
		{
			results.Add(new Dictionary
			{
				{"tag", new StringName(reader.GetString(0))},
				{"color", reader.GetString(1) }
			});
		}
		return results;
	}
	#endregion

	#region Core Operations

	public void TagImage(string hash, StringName tag)
	{
		using var cmd = _connection.CreateCommand();
		cmd.CommandText = "INSERT OR IGNORE INTO image_tags (image_hash, tag) VALUES ($hash, $tag);";
		cmd.Parameters.AddWithValue("$hash", hash);
		cmd.Parameters.AddWithValue("$tag", tag.ToString());
		cmd.ExecuteNonQuery();
	}

	public void UntagImage(string hash, StringName tag)
	{
		using var cmd = _connection.CreateCommand();
		cmd.CommandText = @"DELETE FROM image_tags WHERE image_hash = $hash AND tag = $tag;";
		cmd.Parameters.AddWithValue("$hash", hash);
		cmd.Parameters.AddWithValue("$tag", tag.ToString());
		cmd.ExecuteNonQuery();
	}

	public Array<Dictionary> GetImagesWithTag(string tag)
	{
		var results = new Array<Dictionary>();
		using var cmd = _connection.CreateCommand();
		cmd.CommandText = @"
			SELECT images.hash, images.path, images.fingerprint, images.metadata
			FROM IMAGES
			JOIN image_tags ON images.hash = image_tags.image_hash
			WHERE image_tags.tag = $tag;
		";
		cmd.Parameters.AddWithValue("$tag", tag);

		using var reader = cmd.ExecuteReader();
		while (reader.Read())
		{

			results.Add(new Dictionary
			{
				{"hash", reader.GetString(0) },
				{"path", reader.GetString(1)},
				{"fingerprint", reader.GetString(2)},
				{"metadata", reader.IsDBNull(3)? "{}" : reader.GetString(3)},
			});
		}

		return results;
	}

	public Array<Dictionary> GetTagsForImage(string hash)
	{
		var results = new Array<Dictionary>();
		using var cmd = _connection.CreateCommand();
		cmd.CommandText = @"
			SELECT tags.name, tags.color
			FROM tags
			JOIN image_tags ON tags.name = image_tags.tag
			WHERE image_tags.image_hash = $hash;
		"; cmd.Parameters.AddWithValue("$hash", hash);

		using var reader = cmd.ExecuteReader();
		while (reader.Read())
		{
			results.Add(new Dictionary
			{
				{"tag", new StringName(reader.GetString(0))},
				{"color", reader.IsDBNull(1)? "" : reader.GetString(1)}
			});
		}
		return results;
	}
	#endregion

	#region Search
	public Array<Dictionary> Search(Array<StringName> inclusiveTags, Array<StringName> ExclusiveTags, string nameFilter = null)
	{
		var results = new Array<Dictionary>();
		var cmd = _connection.CreateCommand();

		var incParams = new List<string>();
		for (int i = 0; i < inclusiveTags.Count; i++)
		{
			string param = $"$inc{i}";
			cmd.Parameters.AddWithValue(param, inclusiveTags[i].ToString());
			incParams.Add(param);
		}

		cmd.CommandText = $@"
		SELECT images.*
		FROM images
		WHERE images.hash IN (
			SELECT image_hash
			FROM image_tags
			WHERE tag IN ({string.Join(",", incParams)})
			GROUP BY image_hash
			HAVING COUNT(DISTINCT tag) = {inclusiveTags.Count})
		{(!string.IsNullOrEmpty(nameFilter) ? "" : "AND path LIKE $filter")}
			";

		if (!string.IsNullOrEmpty(nameFilter))
		{
			cmd.Parameters.AddWithValue("$filter", nameFilter);
		}

		var reader = cmd.ExecuteReader();
		while (reader.Read())
		{
			results.Add(new Dictionary
			{
				{"hash", reader.GetString(0)},
				{"path", reader.GetString(1)},
				{"fingerprint", reader.GetString(2)},
				{"metadata", reader.IsDBNull(3)? "{}" : reader.GetString(3)},
			});
		}

		return results;

	}
	#endregion

	public override void _ExitTree()
	{
		CloseDatabase();
	}
}