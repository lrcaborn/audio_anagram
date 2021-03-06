Set-ExecutionPolicy RemoteSigned

clear

function Get-ScriptDirectory
{
    $Invocation = (Get-Variable MyInvocation -Scope 1).Value
    Split-Path $Invocation.MyCommand.Path
}


$timer_total = [System.Diagnostics.Stopwatch]::StartNew()

$sox = "C:\Program Files (x86)\sox-14-4-1\sox.exe"

$allowed_extensions = @(“*.wav", "*.flac", "*.mp3")

$script_dir = Get-ScriptDirectory

$input_dir_template = $script_dir + "\_input"
$output_dir_template = $script_dir + "\_output"
$output_dir_template = "F:\_output"

$project_dir = "\src"

$input_dir=$input_dir_template + $project_dir
$output_dir=$output_dir_template + $project_dir

if ((Test-Path "$output_dir"))
{
    # Clean the output directory
    ls "$output_dir" | Remove-Item -Recurse
}
else
{
    md "$output_dir"
}





$files = ls "$input_dir" | ls -Include $allowed_extensions -Recurse

$file_count = $files.count

# "s" = samples
# "t" = time
$split_by = "s"

# SEGMENT_LENGTH is how long each segment is that will be stitched together later.
# INCREMENT is how far ahead to jump to pull the next segment.
# These don't have to be equal. There will be some repetition, but this is creativity.
# You're allowed to break whatever rules you imagine there to be.

# split by samples
# 44100 samples/second
# 44100 = 1s
# 22050 = 1/2s
# 11025 = 1/4s
# 5513 = 1/8s
# 2756 = 1/16s
# 1378 = 1/32s
# 689 = 1/64s
# 345 = 1/128s
# 172 = 1/256s
# 44100 = 1s
# 4410 = 1/10s
# 441 = 1/100s
# 44 = 1/1000s
$segment_length_min = 441
$segment_length_max = 882

$increment_factor = 1
$increment_min = $segment_length_min * $increment_factor
$increment_max = $segment_length_max / $increment_factor

if ($increment_min -gt $increment_max)
{
    $increment_min = $segment_length_max / $increment_factor
    $increment_max = $segment_length_min * $increment_factor
}

foreach ($file in $files)
{
#    $timer_local = [System.Diagnostics.Stopwatch]::StartNew()

    $file_extension = $file.Extension
    $current_position = 0
    $length = & "$sox" --info -s $file # samples
	#$length = & "$sox" --info -D $file # TIME

    $local_output_dir = $output_dir + "\" + $file.BaseName
    New-Item -ItemType Directory -Force -Path $local_output_dir

    while ($current_position -le $length)
    {
        if ($segment_length_min -eq $segment_length_max)
        {
            $segment_length = $segment_length_min
        }
        else
        {
            $segment_length = Get-Random -Minimum $segment_length_min -Maximum $segment_length_max
        }

        if ($increment_min -eq $increment_max)
        {
            $increment = $increment_min
        }
        else
        {
            [int]$increment = Get-Random -Minimum $increment_min -Maximum $increment_max
        }

        $segment_length_param = $segment_length.ToString() + $split_by

	    Write-Output "length: $length current_position: $current_position segment_length: $segment_length increment: $increment"

        $current_position_param = $current_position.ToString() + $split_by
        $remaining_length = $length - $current_position
        $tmp_output_filename = $local_output_dir + "\" + [System.Guid]::NewGuid().toString() + $file_extension

        if ($remaining_length -lt $segment_length)
        {
            $segment_length_param = $remaining_length.ToString() + $split_by
        }

        & "$sox" "$file" "$tmp_output_filename" trim $current_position_param $segment_length_param

        $current_position = $current_position + $increment
    }

#    Write-Output "Elapsed Time: $($timer_local.Elapsed.ToString())"
}

Write-Output "Elapsed Time: $($timer_total.Elapsed.ToString())"



Function Join-OutputFiles
{

}
