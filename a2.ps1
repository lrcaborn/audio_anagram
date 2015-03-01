Set-ExecutionPolicy RemoteSigned

clear

function Get-ScriptDirectory
{
    $Invocation = (Get-Variable MyInvocation -Scope 1).Value
    Split-Path $Invocation.MyCommand.Path
}


$timer_total = [System.Diagnostics.Stopwatch]::StartNew()


$current_dir = Get-ScriptDirectory
#$input_dir = "D:\Audio\Library"
$input_dir="D:\Audio\Projects\a2g\_input\reiverb"
$sox = "C:\Program Files (x86)\sox-14-4-1\sox.exe"
$output_dir="D:\Audio\Projects\a2g\_output"


# Clean the output directory
ls "$output_dir" | Remove-Item
#Remove-Item $output_dir -Force -Recurse
#New-Item $output_dir -ItemType directory

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

$files = ls "$input_dir" | ls -filter *.flac

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

#        Write-Output $sox
#        Write-Output "$file"
#        Write-Output "$output_filename" trim 
#        Write-Output $current_position_param
#        Write-Output $segment_length_param


        & "$sox" "$file" "$output_filename" trim $current_position_param $segment_length_param

        Write-Output ( ($current_position / $length) % 1).ToString()

        if ( ([math]::log($current_position) / [math]::log($length)) % 1 -eq 0)
        {
            Write-Output "Elapsed Time: $($timer_local.Elapsed.ToString())"
        }
        $current_position = $current_position + $increment

    }
}


$file_counter = 0

$all_data = @{}

$timer = [System.Diagnostics.Stopwatch]::StartNew()

foreach ($file in $files)
{
    $timer_local = [System.Diagnostics.Stopwatch]::StartNew()

    $length = & "$sox" --info -s $file.FullName

    $hash = Get-FileHash $file.FullName -Algorithm SHA1

    $properties = @{
                'FullPath' = $file.FullName;
                'Length' = $length
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

($all_data | ConvertTo-Xml -Depth 2 -NoTypeInformation).Save("$current_dir\crap.xml")
