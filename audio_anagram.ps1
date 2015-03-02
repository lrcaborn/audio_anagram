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

$project_dir = "\tang"

#$input_dir="D:\Audio\Projects\audio_anagram\_input\reiverb"
$input_dir=$input_dir_template + $project_dir
$output_dir=$output_dir_template + $project_dir

if ((Test-Path "$output_dir"))
{
    # Clean the output directory
    ls "$output_dir" | Remove-Item
}
else
{
    md "$output_dir"
}


# SEGMENT_LENGTH is how long each segment is that will be stitched together later.
# INCREMENT is how far ahead to jump to pull the next segment.
# These don't have to be equal. There will be some repetition, but this is creativity.
# You're allowed to break whatever rules you imagine there to be.

# split by samples
$segment_length = "17500"
$increment = "10000"
$segment_length_param = $segment_length.ToString() + "s"

# split by seconds
#$segment_length = 0.4
#$increment = 0.25


$files = ls "$input_dir" | ls -Include $allowed_extensions -Recurse

$file_count = $files.count

# "s" = samples
# "t" = time
$split_by = "s"


# if there is just one file, we are going to slice and dice it alone.
# starting from the beginning of the file,
# loop thru by $increment and extract $segment_length audio
# When finished with the extraction, proceed with building the file info db,
# which will be used for constructing the new audio file.
if ($file_count -eq 1)
{
    $timer_local = [System.Diagnostics.Stopwatch]::StartNew()

    $file = $files
    $file_extension = $file.Extension
    $current_position = 0
    $length = & "$sox" --info -s $file

    while ($current_position -le $length)
    {
        $current_position_param = $current_position.ToString() + "s"
        $remaining_length = $length - $current_position
        $output_filename = "$output_dir\" + [System.Guid]::NewGuid().toString() + $file_extension

        if ($remaining_length -lt $segment_length)
        {
            $segment_length_param = $remaining_length.ToString() + "s"
        }

        & "$sox" "$file" "$output_filename" trim $current_position_param $segment_length_param

        $current_position = $current_position + $increment
    }
    Write-Output "Elapsed Time: $($timer_local.Elapsed.ToString())"

    $files = ls "$output_dir" | ls -Include $allowed_extensions -Recurse
    $file_count = $files.count
}


$file_counter = 0

$all_data = @{}

$timer = [System.Diagnostics.Stopwatch]::StartNew()

foreach ($file in $files)
{
    $timer_local = [System.Diagnostics.Stopwatch]::StartNew()

    $length = & "$sox" --info -s "$file".FullName
    $volume = & "$sox" $file.FullName -n stat -v

    $hash = (Get-FileHash $file -Algorithm SHA1).Hash

    $properties = @{
                'FullPath' = $file.FullName;
                'Length' = $length;
                'Volume' = $volume
            }

    $object = New-Object –TypeName PSObject –Prop $properties

    $all_data.Add($hash, $object)
    $file_counter += 1

    Write-Output "$file_counter / $file_count"

    if ($file_counter % 10 -eq 0)
    {
        Write-Output "Elapsed Time: $($timer_local.Elapsed.ToString())"
    }
}

Write-Output "Total Elapsed Time: $($timer_total.Elapsed.ToString())"

($all_data | ConvertTo-Xml -Depth 2 -NoTypeInformation).Save("$output_dir\_data.xml")
