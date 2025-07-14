using System;
using Godot;
using Godot.Collections;
using Microsoft.Data.Sqlite;


public partial class DatabaseManager : Node
{
    private SqliteConnection connection;

    [Export]
    private string _databasePath;

    public string DatabasePath
    {
        get => _databasePath;
        set => SetDatabasePath(value);
    }

    public override void _Ready()
    {
        base._Ready();
    }

    public void SetDatabasePath(string path)
    {
        Close();
        _databasePath = path;
        OpenDatabase();
        InitializeSchema();
    }

    public void OpenDatabase()
    {
        var absolutePath = DatabasePath;
        GD.Print(absolutePath);
        connection = new SqliteConnection($"Data source={absolutePath}");
        connection.Open();
        GD.Print($"Opened SQLite database at {absolutePath}");
    }

    public void InitializeSchema()
    {
        SqliteCommand command = connection.CreateCommand();
        command.CommandText = @"
        CREATE TABLE IF NOT EXISTS images (
            hash        TEXT PRIMARY KEY,
            tags        TEXT,
            fingerprint TEXT NOT NULL,
            path        TEXT NOT NULL,
            metadata    TEXT NOT NULL
        );

        CREATE TABLE IF NOT EXISTS tags (
            name TEXT PRIMARY KEY,
            color TEXT
        );

        CREATE TABLE IF NOT EXISTS image_tags (
            tag TEXT,
            image_hash TEXT,
            PRIMARY KEY (tag, image_hash),
            FOREIGN KEY (tag) REFERENCES tags(name),
            FOREIGN KEY (image_hash) REFERENCES images(hash)
        )
        ";
        command.ExecuteNonQuery();
    }

    public void AddImage(string hash, string filePath, string fingerprint, string metaDataJson = "{}")
    {
        var cmd = connection.CreateCommand();
        cmd.CommandText = @"INSERT OR REPLACE INTO images (hash, path, tags, fingerprint, metadata) VALUES ($hash, $path, $tags, $fingerprint, $metadata);";
        cmd.Parameters.AddWithValue("$hash", hash);
        cmd.Parameters.AddWithValue("$path", filePath);
        cmd.Parameters.AddWithValue("$tags", "");
        cmd.Parameters.AddWithValue("$fingerprint", fingerprint);
        cmd.Parameters.AddWithValue("$metadata", metaDataJson);
        cmd.ExecuteNonQuery();
    }

    public void AddTag(string tag, string colorHex)
    {
        var cmd = connection.CreateCommand();
        cmd.CommandText = @"INSERT OR REPLACE INTO tags (name, color) VALUES ($name, $color);";
        cmd.Parameters.AddWithValue("$name", tag);
        cmd.Parameters.AddWithValue("$color", colorHex);
        cmd.ExecuteNonQuery();
    }

    public void TagImage(string hash, string tag)
    {
        var cmd = connection.CreateCommand();
        cmd.CommandText = @"INSERT OR IGNORE INTO image_tags (image_hash, tag) values ($hash, $tag);";
        cmd.Parameters.AddWithValue("$hash", hash);
        cmd.Parameters.AddWithValue("$tag", tag);
        cmd.ExecuteNonQuery();

        UpdateImageTagsColumn(hash);
    }

    public void UntagImage(string hash, string tag)
    {
        var cmd = connection.CreateCommand();
        cmd.CommandText = @"DELETE FROM image_tags WHERE image_hash = $hash AND tag = $tag;";
        cmd.Parameters.AddWithValue("$hash", hash);
        cmd.Parameters.AddWithValue("$tag", tag);
        cmd.ExecuteNonQuery();

        UpdateImageTagsColumn(hash);
    }

    public void UpdateImagePath(string hash, string newPath)
    {
        var cmd = connection.CreateCommand();
        cmd.CommandText = @"UPDATE images SET path = $path WHERE hash = $hash;";
        cmd.Parameters.AddWithValue("$path", newPath);
        cmd.Parameters.AddWithValue("$hash", hash);
        cmd.ExecuteNonQuery();
    }

    public Array<string> GetTagsForImage(string hash)
    {
        var tags = new Array<string>();

        var cmd = connection.CreateCommand();
        cmd.CommandText = @"
            SELECT tag from image_tags
            where image_hash = $hash;
        ";

        cmd.Parameters.AddWithValue("$hash", hash);

        var reader = cmd.ExecuteReader();
        while (reader.Read())
        {
            tags.Add(reader.GetString(0));
        }

        reader.Close();
        return tags;
    }

    public Dictionary<string, Variant> GetImageInfo(string hash)
    {

        var cmd = connection.CreateCommand();

        cmd.CommandText = @"SELECT hash, path, fingerprint, tags FROM images where hash = $hash;";
        cmd.Parameters.AddWithValue("$hash", hash);

        var reader = cmd.ExecuteReader();

        if (!reader.Read()) { return null; }

        var result = new Dictionary<string, Variant>
        {
            ["hash"] = reader.GetString(0),
            ["path"] = reader.GetString(1),
            ["fingerprint"] = reader.GetString(2),
            ["tags"] = reader.GetString(3)
        };

        return result;
    }

    private void UpdateImageTagsColumn(string hash)
    {
        var tagString = string.Join("|", GetTagsForImage(hash));

        var cmd = connection.CreateCommand();
        cmd.CommandText = @"UPDATE images SET tags = $tags where hash = $hash";
        cmd.Parameters.AddWithValue("$tags", tagString);
        cmd.Parameters.AddWithValue("$hash", hash);
        cmd.ExecuteNonQuery();
    }

    public void Close()
    {
        connection?.Close();
        connection = null;
    }

    public override void _ExitTree()
    {
        base._ExitTree();
        Close();
    }
}
