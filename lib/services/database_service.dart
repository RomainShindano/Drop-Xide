import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  static Database? _database;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'drop_xide.db');

    return await openDatabase(
      path,
      version: 2,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE projects (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        path TEXT NOT NULL UNIQUE,
        description TEXT,
        added_at INTEGER NOT NULL,
        last_build_at INTEGER,
        last_build_config TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE build_history (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        project_name TEXT NOT NULL,
        build_config TEXT NOT NULL,
        started_at INTEGER NOT NULL,
        completed_at INTEGER,
        status TEXT NOT NULL,
        output_path TEXT,
        error_message TEXT,
        logs TEXT,
        FOREIGN KEY (project_id) REFERENCES projects (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE service_accounts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        project_id TEXT NOT NULL,
        added_at INTEGER NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        credentials TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE publish_history (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        project_name TEXT NOT NULL,
        package_name TEXT NOT NULL,
        service_account_id TEXT NOT NULL,
        aab_path TEXT NOT NULL,
        version_name TEXT NOT NULL,
        version_code INTEGER NOT NULL,
        track TEXT NOT NULL,
        release_notes TEXT NOT NULL,
        rollout_percentage REAL,
        started_at INTEGER NOT NULL,
        completed_at INTEGER,
        status TEXT NOT NULL,
        error_message TEXT,
        FOREIGN KEY (project_id) REFERENCES projects (id) ON DELETE CASCADE,
        FOREIGN KEY (service_account_id) REFERENCES service_accounts (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_build_history_project_id ON build_history(project_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_build_history_started_at ON build_history(started_at DESC)
    ''');

    await db.execute('''
      CREATE INDEX idx_publish_history_project_id ON publish_history(project_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_publish_history_started_at ON publish_history(started_at DESC)
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add publish_history table (from v1 to v2)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS publish_history (
          id TEXT PRIMARY KEY,
          project_id TEXT NOT NULL,
          project_name TEXT NOT NULL,
          package_name TEXT NOT NULL,
          service_account_id TEXT NOT NULL,
          aab_path TEXT NOT NULL,
          version_name TEXT NOT NULL,
          version_code INTEGER NOT NULL,
          track TEXT NOT NULL,
          release_notes TEXT NOT NULL,
          rollout_percentage REAL,
          started_at INTEGER NOT NULL,
          completed_at INTEGER,
          status TEXT NOT NULL,
          error_message TEXT,
          FOREIGN KEY (project_id) REFERENCES projects (id) ON DELETE CASCADE,
          FOREIGN KEY (service_account_id) REFERENCES service_accounts (id) ON DELETE CASCADE
        )
      ''');
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_publish_history_project_id
        ON publish_history(project_id)
      ''');
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_publish_history_started_at
        ON publish_history(started_at DESC)
      ''');
      
      // Add build_queue and build_templates tables
      await db.execute('''
        CREATE TABLE IF NOT EXISTS build_queue (
          id TEXT PRIMARY KEY,
          project_id TEXT NOT NULL,
          project_name TEXT NOT NULL,
          build_config TEXT NOT NULL,
          queued_at INTEGER NOT NULL,
          started_at INTEGER,
          completed_at INTEGER,
          status TEXT NOT NULL,
          priority INTEGER NOT NULL DEFAULT 0,
          build_history_id TEXT,
          FOREIGN KEY (project_id) REFERENCES projects (id) ON DELETE CASCADE,
          FOREIGN KEY (build_history_id) REFERENCES build_history (id) ON DELETE SET NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS build_templates (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL UNIQUE,
          description TEXT,
          build_config TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          last_used_at INTEGER,
          usage_count INTEGER NOT NULL DEFAULT 0,
          is_favorite INTEGER NOT NULL DEFAULT 0
        )
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_build_queue_status ON build_queue(status)
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_build_queue_priority
        ON build_queue(priority DESC, queued_at ASC)
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_build_templates_favorite
        ON build_templates(is_favorite DESC, last_used_at DESC)
      ''');
    }
  }

  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data);
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    final db = await database;
    return await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
    );
  }

  Future<int> update(
    String table,
    Map<String, dynamic> data, {
    required String where,
    required List<dynamic> whereArgs,
  }) async {
    final db = await database;
    return await db.update(table, data, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(
    String table, {
    required String where,
    required List<dynamic> whereArgs,
  }) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
