class ToolLaunchSerializer
  def self.render(tool_launch)
    {
      id: tool_launch.id,
      organization_id: tool_launch.organization_id,
      user_id: tool_launch.user_id,
      course_id: tool_launch.course_id,
      launch_context: tool_launch.launch_context,
      launched_at: tool_launch.launched_at
    }
  end
end
