extends Node2D


var textboxname = 'def'
#this name must be UNIQUE!!!!
#If you create another textbox by the same name as an existing one, it'll have the same name + '+'
var fulltext = ''
var latesttext = ''
var latestposition = 0



func _ready():
	pass


func set_text():
	pass



func _physics_process(delta):
	if get_parent().framepos <= get_parent().framepos_max:
		if latestposition == get_parent().scenepos:
			get_node('scrollingText').text = fulltext.substr(0,int(get_parent().framepos*global.settings['textspeed'])+1)
	else: get_node('scrollingText').text = fulltext
	
