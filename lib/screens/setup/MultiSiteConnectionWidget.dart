import 'package:flutter/material.dart';
import 'dart:math';
import '../../models/site_connection.dart';
import '../../services/secureStorage.dart';
import '../../services/site_connection_service.dart';
import '../../services/apiRequest.dart';
import '../../services/authService.dart';
import 'ConnectionSettingsWidget.dart';

class MultiSiteConnectionWidget extends StatefulWidget {
  final Function(bool) onClose;

  const MultiSiteConnectionWidget({Key? key, required this.onClose}) : super(key: key);

  @override
  _MultiSiteConnectionWidgetState createState() => _MultiSiteConnectionWidgetState();
}

class _MultiSiteConnectionWidgetState extends State<MultiSiteConnectionWidget> {
  final SecureStorage _secureStorage = SecureStorage();
  late SiteConnectionService _connectionService;
  late AuthenticationService _authService;
  
  List<SiteConnection> _connections = [];
  String? _activeConnectionId;
  bool _isLoading = true;
  bool _isEditing = false;
  SiteConnection? _editingConnection;

  @override
  void initState() {
    super.initState();
    _connectionService = SiteConnectionService(_secureStorage);
    _authService = AuthenticationService(_secureStorage, ApiRequest());
    _loadConnections();
  }

  Future<void> _loadConnections() async {
    setState(() {
      _isLoading = true;
    });

    // Migrate legacy connection if needed
    await _connectionService.migrateLegacyConnection();
    
    // Load all connections
    final connections = await _connectionService.getAllConnections();
    final activeId = await _connectionService.getActiveConnectionId();
    
    setState(() {
      _connections = connections;
      _activeConnectionId = activeId;
      _isLoading = false;
    });
  }

  void _addNewConnection() {
    setState(() {
      _isEditing = true;
      _editingConnection = SiteConnection(
        id: '',
        name: 'New Connection',
        protocol: 'https',
        server: '',
        site: '',
        username: '',
        password: '',
      );
    });
  }

  void _editConnection(SiteConnection connection) {
    setState(() {
      _isEditing = true;
      _editingConnection = connection;
    });
  }

  Future<void> _deleteConnection(String connectionId) async {
    await _connectionService.deleteConnection(connectionId);
    await _loadConnections();
  }

  Future<void> _setActiveConnection(String connectionId) async {
    await _connectionService.setActiveConnection(connectionId);
    
    // Get the connection and try to login
    final connection = await _connectionService.getConnection(connectionId);
    if (connection != null) {
      await _authService.login(connection.username, connection.password);
    }
    
    setState(() {
      _activeConnectionId = connectionId;
    });
  }

  void _closeEditor(bool saved) async {
    if (saved && _editingConnection != null) {
      if (_editingConnection!.id.isEmpty) {
        // This is a new connection
        final newConnection = await _connectionService.addConnection(_editingConnection!);
        
        // If this is the first connection, set it as active
        if (_connections.isEmpty) {
          await _setActiveConnection(newConnection.id);
        }
      } else {
        // This is an existing connection
        await _connectionService.updateConnection(_editingConnection!);
        
        // If this is the active connection, try to login again
        if (_editingConnection!.id == _activeConnectionId) {
          await _authService.login(_editingConnection!.username, _editingConnection!.password);
        }
      }
      
      await _loadConnections();
    }
    
    setState(() {
      _isEditing = false;
      _editingConnection = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_isEditing) {
      return ConnectionEditorWidget(
        connection: _editingConnection!,
        onSave: (updatedConnection) {
          setState(() {
            _editingConnection = updatedConnection;
          });
          _closeEditor(true);
        },
        onCancel: () => _closeEditor(false),
      );
    }
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Manage Connections',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        
        if (_connections.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'No connections configured. Add a new connection to get started.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          )
        else
          Container(
            height: 300, // Fixed height to avoid layout issues
            child: ListView.builder(
              shrinkWrap: false,
              itemCount: _connections.length,
              itemBuilder: (context, index) {
                final connection = _connections[index];
                final isActive = connection.id == _activeConnectionId;
                
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: ListTile(
                    title: Text(connection.name),
                    subtitle: Text('${connection.protocol}://${connection.server}${connection.site.isNotEmpty ? '/${connection.site}' : ''}'),
                    leading: isActive 
                      ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                      : Icon(Icons.circle_outlined),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editConnection(connection),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteConnection(connection.id),
                        ),
                      ],
                    ),
                    onTap: () {
                      if (!isActive) {
                        _setActiveConnection(connection.id);
                      }
                    },
                  ),
                );
              },
            ),
          ),
        
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add New Connection'),
            onPressed: _addNewConnection,
          ),
        ),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: ElevatedButton(
            onPressed: () => widget.onClose(true),
            child: const Text('Close'),
          ),
        ),
        ],
      ),
    );
  }
}

class ConnectionEditorWidget extends StatefulWidget {
  final SiteConnection connection;
  final Function(SiteConnection) onSave;
  final VoidCallback onCancel;

  const ConnectionEditorWidget({
    Key? key,
    required this.connection,
    required this.onSave,
    required this.onCancel,
  }) : super(key: key);

  @override
  _ConnectionEditorWidgetState createState() => _ConnectionEditorWidgetState();
}

class _ConnectionEditorWidgetState extends State<ConnectionEditorWidget> {
  final _formKey = GlobalKey<FormState>();
  late SiteConnection _connection;
  
  final _nameController = TextEditingController();
  final _serverController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _siteController = TextEditingController();
  
  String _protocol = 'https';
  bool _ignoreCertificate = false;
  bool _enableNotifications = false;
  
  // Service state notification settings
  late Map<String, bool> _serviceStateNotifications;

  @override
  void initState() {
    super.initState();
    _connection = widget.connection;
    
    _nameController.text = _connection.name;
    _protocol = _connection.protocol;
    _serverController.text = _connection.server;
    _siteController.text = _connection.site;
    _usernameController.text = _connection.username;
    _passwordController.text = _connection.password;
    _ignoreCertificate = _connection.ignoreCertificate;
    _enableNotifications = _connection.enableNotifications;
    _serviceStateNotifications = Map.from(_connection.serviceStateNotifications);
  }

  SiteConnection _getUpdatedConnection() {
    return _connection.copyWith(
      id: _connection.id.isEmpty ? _generateUuid() : _connection.id,
      name: _nameController.text,
      protocol: _protocol,
      server: _serverController.text,
      site: _siteController.text,
      username: _usernameController.text,
      password: _passwordController.text,
      ignoreCertificate: _ignoreCertificate,
      enableNotifications: _enableNotifications,
      serviceStateNotifications: _serviceStateNotifications,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _connection.id.isEmpty ? 'Add New Connection' : 'Edit Connection',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Connection Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name for this connection';
                }
                return null;
              },
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: DropdownButtonFormField<String>(
              value: _protocol,
              decoration: const InputDecoration(
                labelText: 'Protocol',
                border: OutlineInputBorder(),
              ),
              items: <String>['http', 'https']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _protocol = newValue!;
                });
              },
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextFormField(
              controller: _serverController,
              decoration: const InputDecoration(
                labelText: 'Server',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a server address';
                }
                return null;
              },
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextFormField(
              controller: _siteController,
              decoration: const InputDecoration(
                labelText: 'Site Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a site name';
                }
                return null;
              },
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a username';
                }
                return null;
              },
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a password';
                }
                return null;
              },
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SwitchListTile(
              title: const Text('Ignore Certificate Warnings'),
              value: _ignoreCertificate,
              onChanged: _protocol == 'https'
                  ? (bool value) {
                      setState(() {
                        _ignoreCertificate = value;
                      });
                    }
                  : null,
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SwitchListTile(
              title: const Text('Enable Background Notifications'),
              value: _enableNotifications,
              onChanged: (bool value) {
                setState(() {
                  _enableNotifications = value;
                });
              },
            ),
          ),

          // Service State Notification Settings
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ExpansionTile(
              title: const Text('Service State Notifications'),
              children: _serviceStateNotifications.keys.map((state) {
                return SwitchListTile(
                  title: Text('Notify on $state state'),
                  value: _serviceStateNotifications[state] ?? true,
                  onChanged: (bool? value) {
                    setState(() {
                      _serviceStateNotifications[state] = value ?? true;
                    });
                  },
                );
              }).toList(),
            ),
          ),

          // Save and Cancel buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: widget.onCancel,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      widget.onSave(_getUpdatedConnection());
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }

  // Generate a simple UUID
  String _generateUuid() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    
    return values.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join('');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _serverController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _siteController.dispose();
    super.dispose();
  }
}
