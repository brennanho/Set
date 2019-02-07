extends Node
const udp_client_port = 56883
const udp_server_port = 56884
const port = 56885

# EXECUTED ON CLIENT SIDE
remote func update_players_lobby(players, id):
	global.players_in_lobby = players
	global.my_name = id
	get_parent().add_players_to_screen(global.players_in_lobby)
	
remote func add_new_client_to_other_client(id):
	get_parent().add_player_to_screen(id)
	
remote func remove_client_from_other_client(id):
	get_parent().remove_player_from_screen(id)

func _connected_to_server(id):
	print('Client ' + str(id) + ' connected to Server')

func _connect_to_server_fail():
	print('Client failed to connect to Server')

func _connect_to_server_success():
	print('Client connected to Server')

func _disconnected_from_server(id):
	print('Client' + str(id) + ' disconnected from Server')
	get_tree().change_scene(global.prev_scene)
	global.refresh_globals()

# EXECUTED ON SERVER SIDE
func _client_connected(id):
	print('Client ' + str(id) + ' has joined')
	get_parent().add_player_to_screen(id)
	for player_id in global.players_in_lobby.keys():
		if player_id != 1 and player_id != id:
			rpc_id(player_id, "add_new_client_to_other_client", id)
	rpc_id(id, "update_players_lobby", global.players_in_lobby, id)

func _client_disconnected(id):
	print('Client ' + str(id) + ' has left')
	for player_id in global.players_in_lobby.keys():
		if player_id != 1 and player_id != id:
			rpc_id(player_id, "remove_client_from_other_client", id)
	get_parent().remove_player_from_screen(id)
		
func broadcast_to_clients(nil):
	global.udp_sock = PacketPeerUDP.new()
	var my_ip = global.get_host_ip()
	global.udp_sock.listen(udp_server_port)
	global.discovery_on = true
	while global.discovery_on:
		var client_ip = global.udp_sock.get_var()
		if client_ip != null:
			#print("Sending ", client_ip, " my server_ip ", my_ip)
			global.udp_sock.set_dest_address(client_ip, udp_client_port)
			global.udp_sock.put_var(my_ip)
			client_ip = null
		OS.delay_msec(100)
	return 0
	
func init_server():
	global.peer = NetworkedMultiplayerENet.new()	
	global.server_ip = global.get_host_ip()
	global.peer.create_server(port, 5)
	global.my_name = 1
	global.peer.set_always_ordered(true)
	global.peer.transfer_mode = global.peer.TRANSFER_MODE_RELIABLE
	get_tree().set_network_peer(global.peer)
	get_tree().connect("network_peer_connected",    self, "_client_connected")
	get_tree().connect("network_peer_disconnected", self, "_client_disconnected")
	return global.peer

func init_client(ip):
	global.peer = NetworkedMultiplayerENet.new()
	global.peer.create_client(ip, port)
	global.peer.set_always_ordered(true) 
	global.peer.transfer_mode = global.peer.TRANSFER_MODE_RELIABLE
	get_tree().set_network_peer(global.peer)
	get_tree().connect("connected_to_server",  self,  "_connected_to_server", [global.peer.get_unique_id()])
	get_tree().connect("connection_failed",    self,  "_connect_to_server_fail")
	get_tree().connect("server_disconnected",  self,  "_disconnected_from_server", [ip])
	return global.peer