bl_info = {
  "name": "PLY Exporter Utility for Desmos Plane",
  "blender": (2, 92, 0),
  "category": "Object",
}

import bpy

# class ExportVisibleMenu(bpy.types.Menu):
#   bl_idname = "view3D.export_visible"
#   bl_label = "Export Visible as PLY"

#   def draw(self, context):
#     layout = self.layout

#     layout.operator("mesh.primitive_cube_add")
#     layout.operator("object.duplicate_move")   
#     # layout.operator("object.select_all", text="Select/Deselect All").action = 'TOGGLE'

class VIEW3D_OT_export_visible(bpy.types.Operator):
  bl_idname = "mesh.export_visible"
  bl_label = "Export Visible Objects as PLY"

  def execute(self, context):
    print("PLY EXPORT: ")
    for obj in context.scene.objects:
      obj.select_set(False)
      if obj.visible_get():
        print("Exporting " + obj.name +" ...")
        obj.select_set(True)
        bpy.ops.export_mesh.ply(
          filepath=bpy.path.abspath("//" + obj.name + ".ply"),
          use_selection=True,
          check_existing=False,
          use_ascii=True,
          axis_forward="Z",
          axis_up="Y"
        )
        obj.select_set(False)


    return {'FINISHED'}


def draw_export_visible(self, context):
  self.layout.operator(VIEW3D_OT_export_visible.bl_idname, text=VIEW3D_OT_export_visible.bl_label)

def register():
  bpy.utils.register_class(VIEW3D_OT_export_visible)
  bpy.types.VIEW3D_MT_object.append(draw_export_visible)
  print("GOT HERE")
  #bpy.ops.wm.call_menu(name=ExportVisibleMenu.bl_idname)  

def unregister():
  bpy.types.VIEW3D_MT_object.remove(draw_export_visible)
  bpy.utils.unregister_class(VIEW3D_OT_export_visible)

if __name__ == "__main__": register()