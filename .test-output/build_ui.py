from pathlib import Path
root=Path('.')
theme='''[gd_resource type="Theme" load_steps=8 format=3]

[sub_resource type="StyleBoxFlat" id="Panel"]
content_margin_left = 20.0
content_margin_top = 18.0
content_margin_right = 20.0
content_margin_bottom = 18.0
bg_color = Color(0.055, 0.095, 0.095, 0.96)
border_width_left = 1
border_width_top = 2
border_width_right = 1
border_width_bottom = 1
border_color = Color(0.55, 0.43, 0.25, 1)
corner_radius_top_left = 6
corner_radius_top_right = 6
corner_radius_bottom_left = 6
corner_radius_bottom_right = 6
shadow_color = Color(0, 0, 0, 0.35)
shadow_size = 12

[sub_resource type="StyleBoxFlat" id="Button"]
content_margin_left = 16.0
content_margin_top = 10.0
content_margin_right = 16.0
content_margin_bottom = 10.0
bg_color = Color(0.12, 0.2, 0.19, 1)
border_width_left = 1
border_width_top = 1
border_width_right = 1
border_width_bottom = 1
border_color = Color(0.38, 0.46, 0.36, 1)
corner_radius_top_left = 4
corner_radius_top_right = 4
corner_radius_bottom_left = 4
corner_radius_bottom_right = 4

[sub_resource type="StyleBoxFlat" id="Hover"]
content_margin_left = 16.0
content_margin_top = 10.0
content_margin_right = 16.0
content_margin_bottom = 10.0
bg_color = Color(0.24, 0.31, 0.24, 1)
border_width_left = 1
border_width_top = 1
border_width_right = 1
border_width_bottom = 1
border_color = Color(0.88, 0.7, 0.4, 1)
corner_radius_top_left = 4
corner_radius_top_right = 4
corner_radius_bottom_left = 4
corner_radius_bottom_right = 4

[sub_resource type="StyleBoxFlat" id="Disabled"]
content_margin_left = 16.0
content_margin_top = 10.0
content_margin_right = 16.0
content_margin_bottom = 10.0
bg_color = Color(0.1, 0.13, 0.13, 1)

[sub_resource type="StyleBoxFlat" id="Focus"]
bg_color = Color(0, 0, 0, 0)
border_width_left = 2
border_width_top = 2
border_width_right = 2
border_width_bottom = 2
border_color = Color(0.92, 0.77, 0.48, 1)

[sub_resource type="StyleBoxFlat" id="Track"]
bg_color = Color(0.23, 0.29, 0.27, 1)
content_margin_top = 3.0
content_margin_bottom = 3.0

[sub_resource type="StyleBoxFlat" id="Fill"]
bg_color = Color(0.77, 0.61, 0.35, 1)
content_margin_top = 3.0
content_margin_bottom = 3.0

[resource]
default_font_size = 16
Label/colors/font_color = Color(0.93, 0.9, 0.8, 1)
Button/colors/font_color = Color(0.95, 0.92, 0.83, 1)
Button/colors/font_disabled_color = Color(0.5, 0.55, 0.5, 1)
Button/styles/normal = SubResource("Button")
Button/styles/hover = SubResource("Hover")
Button/styles/pressed = SubResource("Hover")
Button/styles/disabled = SubResource("Disabled")
Button/styles/focus = SubResource("Focus")
Panel/styles/panel = SubResource("Panel")
PanelContainer/styles/panel = SubResource("Panel")
HSlider/styles/slider = SubResource("Track")
HSlider/styles/grabber_area = SubResource("Fill")
HSlider/styles/grabber_area_highlight = SubResource("Fill")
HSeparator/colors/separator = Color(0.55, 0.43, 0.25, 0.6)
'''
Path('Scenes/ui/adventure_theme.tres').write_text(theme,encoding='utf-8')
def node(name,typ,parent=None,props=''):
 return f'\n[node name="{name}" type="{typ}"'+(f' parent="{parent}"' if parent else '')+']\n'+props+'\n'
full='layout_mode = 1\nanchors_preset = 15\nanchor_right = 1.0\nanchor_bottom = 1.0\ngrow_horizontal = 2\ngrow_vertical = 2'
label=lambda text,fs=16: f'layout_mode = 2\ntext = "{text}"\ntheme_override_font_sizes/font_size = {fs}'
# Stock / shop / backpack. Keep scene identity, replace the uneven legacy layout.
s='''[gd_scene format=3 uid="uid://dbqktapaen5q"]
[ext_resource type="Script" path="res://Scripts/controllers/camp_controller.gd" id="1"]
[ext_resource type="Theme" path="res://Scenes/ui/adventure_theme.tres" id="2"]
[ext_resource type="Script" path="res://Scripts/resources/item_data.gd" id="3"]
[ext_resource type="Resource" path="res://Scripts/resources/Items/potion_small.tres" id="4"]
[ext_resource type="Resource" path="res://Scripts/resources/Items/potion_medium.tres" id="5"]
[ext_resource type="Resource" path="res://Scripts/resources/Items/strenght_elixir.tres" id="6"]
[ext_resource type="PackedScene" path="res://Scenes/item_card.tscn" id="7"]
'''
s+=node('Camp','Control',props=full+'\ntheme = ExtResource("2")\nscript = ExtResource("1")\nall_items = Array[ExtResource("3")]([ExtResource("4"), ExtResource("5"), ExtResource("6")])\nitem_card_scene = ExtResource("7")')
s+=node('Shade','ColorRect','.',full+'\ncolor = Color(0.015, 0.025, 0.025, 0.32)\nmouse_filter = 2')
s+=node('MarginContainer','MarginContainer','.','layout_mode = 1\nanchor_left = 0.04\nanchor_top = 0.05\nanchor_right = 0.96\nanchor_bottom = 0.95')
s+=node('VBoxContainer','VBoxContainer','MarginContainer','layout_mode = 2\ntheme_override_constants/separation = 14')
v='MarginContainer/VBoxContainer'
s+=node('HBoxContainer','HBoxContainer',v,'layout_mode = 2\ntheme_override_constants/separation = 24')
s+=node('Title','Label',v+'/HBoxContainer',label('PROVISÕES',30)+'\nsize_flags_horizontal = 3')
s+=node('ProfileNameLabel','Label',v+'/HBoxContainer',label('Perfil'))
s+=node('CoinsLabel','Label',v+'/HBoxContainer',label('0 moedas',22)+'\ntheme_override_colors/font_color = Color(0.93, 0.76, 0.43, 1)')
s+=node('Subtitle','Label',v,label('Prepare a mochila antes de partir. O que ficar no baú estará esperando por você.'))
s+=node('HBoxContainer2','HBoxContainer',v,'layout_mode = 2\nsize_flags_vertical = 3\ntheme_override_constants/separation = 18')
for name,title,hint,ratio in [('Shop','MERCADOR','Consumíveis para a próxima expedição.',1.5),('Bag','MOCHILA','Clique em um item para guardar no baú.',1),('Stash','BAÚ','Clique em um item para levar na mochila.',1)]:
 p=v+'/HBoxContainer2'
 s+=node(name,'PanelContainer',p,f'layout_mode = 2\nsize_flags_horizontal = 3\nsize_flags_stretch_ratio = {ratio}\ncustom_minimum_size = Vector2(280, 0)')
 p+='/'+name
 s+=node('VBoxContainer','VBoxContainer',p,'layout_mode = 2\ntheme_override_constants/separation = 14')
 p+='/VBoxContainer'
 s+=node('Label','Label',p,label(title,22))
 s+=node('Hint','Label',p,label(hint,14)+'\nautowrap_mode = 2\ncustom_minimum_size = Vector2(0, 36)\ntheme_override_colors/font_color = Color(0.66, 0.73, 0.66, 1)')
 s+=node('Scroll','ScrollContainer',p,'layout_mode = 2\nsize_flags_vertical = 3\nhorizontal_scroll_mode = 0')
 s+=node('GridContainer','GridContainer',p+'/Scroll',f'layout_mode = 2\nsize_flags_horizontal = 3\ncolumns = {1 if name=="Shop" else 3}\ntheme_override_constants/h_separation = 12\ntheme_override_constants/v_separation = 12')
s+=node('Status','Label',v,label('As compras vão para a mochila. Transfira itens para liberar espaço.',14)+'\ncustom_minimum_size = Vector2(0, 24)')
s+=node('HBoxContainer3','HBoxContainer',v,'layout_mode = 2\ntheme_override_constants/separation = 16')
s+=node('RerollShopButton','Button',v+'/HBoxContainer3','layout_mode = 2\ntext = "Renovar ofertas · 10 moedas"')
s+=node('Spacer','Control',v+'/HBoxContainer3','layout_mode = 2\nsize_flags_horizontal = 3')
s+=node('StartButton','Button',v+'/HBoxContainer3','layout_mode = 2\ntext = "← Voltar ao acampamento"\ncustom_minimum_size = Vector2(260, 48)')
Path('Scenes/main/camp.tscn').write_text(s,encoding='utf-8')
# Compact horizontal shop card.
s='''[gd_scene format=3 uid="uid://bs1pa3rcorq6k"]
[ext_resource type="Script" path="res://Scripts/ui/item_card.gd" id="1"]
'''
s+=node('ItemCard','PanelContainer',props='custom_minimum_size = Vector2(0, 108)\nsize_flags_horizontal = 3\nscript = ExtResource("1")')
s+=node('Row','HBoxContainer','.','layout_mode = 2\ntheme_override_constants/separation = 14')
s+=node('ItemIcon','TextureRect','Row','layout_mode = 2\ncustom_minimum_size = Vector2(48, 64)\nexpand_mode = 1\nstretch_mode = 5\ntexture_filter = 1')
s+=node('Info','VBoxContainer','Row','layout_mode = 2\nsize_flags_horizontal = 3\ntheme_override_constants/separation = 6')
s+=node('NameLabel','Label','Row/Info',label('Poção',17)+'\nautowrap_mode = 2')
s+=node('DescLabel','Label','Row/Info',label('Restaura vida.',13)+'\nautowrap_mode = 2\ntheme_override_colors/font_color = Color(0.67, 0.74, 0.68, 1)')
s+=node('BuyButton','Button','Row','layout_mode = 2\nsize_flags_vertical = 4\ntext = "3 moedas"\ntheme_override_font_sizes/font_size = 14')
Path('Scenes/item_card.tscn').write_text(s,encoding='utf-8')
# Settings overlay leaves the 3D scene visible.
s='''[gd_scene format=3 uid="uid://vb01rocv2w8o"]
[ext_resource type="Script" path="res://settings_scene.gd" id="1"]
[ext_resource type="Theme" path="res://Scenes/ui/adventure_theme.tres" id="2"]
'''
s+=node('Settings','Control',props=full+'\ntheme = ExtResource("2")\nscript = ExtResource("1")')
s+=node('Shade','ColorRect','.',full+'\ncolor = Color(0.01, 0.025, 0.025, 0.2)\nmouse_filter = 2')
s+=node('Panel','PanelContainer','.','layout_mode = 1\nanchor_left = 0.54\nanchor_top = 0.1\nanchor_right = 0.94\nanchor_bottom = 0.9')
s+=node('VBox','VBoxContainer','Panel','layout_mode = 2\ntheme_override_constants/separation = 20')
s+=node('Eyebrow','Label','Panel/VBox',label('ROGUERPG  /  ACAMPAMENTO',13)+'\ntheme_override_colors/font_color = Color(0.82, 0.65, 0.38, 1)')
s+=node('Title','Label','Panel/VBox',label('Configurações',32))
s+=node('Subtitle','Label','Panel/VBox',label('Encontre o som da sua aventura.',16))
s+=node('Separator','HSeparator','Panel/VBox','layout_mode = 2')
for name,title,hint in [('Master','Volume geral','Todo o áudio do jogo'),('Music','Música','Trilha do acampamento e da jornada'),('SFX','Efeitos','Ataques, dados e interface')]:
 s+=node(name,'VBoxContainer','Panel/VBox','layout_mode = 2\ntheme_override_constants/separation = 8')
 p='Panel/VBox/'+name
 s+=node('Heading','HBoxContainer',p,'layout_mode = 2')
 s+=node('Name','Label',p+'/Heading',label(title,18)+'\nsize_flags_horizontal = 3')
 s+=node('Value','Label',p+'/Heading',label('100%',18)+'\ncustom_minimum_size = Vector2(55, 0)\nhorizontal_alignment = 2')
 s+=node('Slider','HSlider',p,'layout_mode = 2\ncustom_minimum_size = Vector2(0, 28)\nmax_value = 1.0\nstep = 0.01')
 s+=node('Hint','Label',p,label(hint,13)+'\ntheme_override_colors/font_color = Color(0.67, 0.74, 0.68, 1)')
s+=node('Spacer','Control','Panel/VBox','layout_mode = 2\nsize_flags_vertical = 3')
s+=node('Back','Button','Panel/VBox','layout_mode = 2\ntext = "← Voltar"\ncustom_minimum_size = Vector2(0, 48)')
Path('Scenes/main/SettingsScene.tscn').write_text(s,encoding='utf-8')
# Remove inherited overrides targeting the old camp tree.
p=Path('Scenes/3D/lobby_3d.tscn');s=p.read_text(encoding='utf-8');a=s.index('[node name="Panel" parent="UILayer/StashUI"');b=s.index('[node name="TransitionLayer"',a);s=s[:a]+s[b:];p.write_text(s,encoding='utf-8')
