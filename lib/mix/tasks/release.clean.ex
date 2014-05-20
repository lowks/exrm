defmodule Mix.Tasks.Release.Clean do
  @moduledoc """
  Clean up any release-related files.

  ## Examples

    # Cleans the release for the current version of the project
    mix release.clean
    # Remove all files generated by exrm, including releases
    mix release.clean --implode

  """
  @shortdoc "Clean up any release-related files."

  use     Mix.Task
  import  ReleaseManager.Utils

  @_RELXCONF  "relx.config"
  @_BOOT_FILE "boot"

  def run(args) do
    debug "Removing release files..."
    cond do
      "--implode" in args ->
        if confirm_implode? do
          do_cleanup :all
          info "All release files were removed successfully!"
        end
      true ->
        do_cleanup :build
        info "The release for #{Mix.Project.config |> Keyword.get(:version)} has been removed."
    end
  end

  # Clean release build
  def do_cleanup(:build) do
    cwd       = File.cwd!
    project   = Mix.Project.config |> Keyword.get(:app) |> atom_to_binary
    version   = Mix.Project.config |> Keyword.get(:version)
    build     = Path.join([cwd, "_build", "prod"])
    release   = rel_dest_path [project, "releases", version]
    releases  = rel_dest_path [project, "releases", "RELEASES"]
    start_erl = rel_dest_path [project, "releases", "start_erl.data"]
    package   = rel_dest_path [project, "#{project}-#{version}.tar.gz"]
    lib       = rel_dest_path [project, "lib", "#{project}-#{version}"]
    relup     = rel_dest_path [project, "relup"]

    if File.exists?(release),   do: File.rm_rf!(release)
    if File.exists?(releases),  do: File.rm_rf!(releases)
    if File.exists?(start_erl), do: File.rm_rf!(start_erl)
    if File.exists?(package),   do: File.rm_rf!(package)
    if File.exists?(lib),       do: File.rm_rf!(lib)
    if File.exists?(relup),     do: File.rm_rf!(relup)
    if File.exists?(build) do
      build
      |> File.ls!
      |> Enum.map(fn dir -> build |> Path.join(dir) end)
      |> Enum.map(&File.rm_rf!/1)
    end
  end
  # Clean up the template files for release generation
  def do_cleanup(:relfiles) do
    rel_files = rel_file_dest_path
    if File.exists?(rel_files), do: File.rm_rf!(rel_files)
  end
  # Clean up everything
  def do_cleanup(:all) do
    # Execute other clean tasks
    do_cleanup :build

    # Remove release folder
    rel = rel_dest_path
    if File.exists?(rel), do: File.rm_rf!(rel)
  end

  defp confirm_implode? do
    IO.puts IO.ANSI.yellow
    confirmed? = Mix.Shell.IO.yes?("""
      THIS WILL REMOVE ALL RELEASES AND RELATED CONFIGURATION!
      Are you absolutely sure you want to proceed?
      """)
    IO.puts IO.ANSI.reset
    confirmed?
  end

end