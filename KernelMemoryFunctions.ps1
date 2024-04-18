# Goto the script's path, fill in whatever path you saved the script and files
Set-Location "C:\Scripts\KernelMemory"


# Start the kernel-memory container, 'appsettings.Development.json' contains the OpenAI key and other container config settings.
function Start-KernelContainer {
    & docker run --volume .\appsettings.Development.json:/app/appsettings.Production.json -it --rm -p 9001:9001 kernelmemory/service
}

# Upload file to the kernel-memory container url, FilePath. The other parameters are still under constructions
function Upload-KernelMemoryDocument {
    param (
    [string]$FilePath
    # [string]$Index,
    # [string]$DocumentId,
    # [string]$Tags
    )
    
    $url = "http://127.0.0.1:9001/upload"
    
    $form = @{
        file1 = Get-Item -Path $FilePath
        index = $Index
        documentId = $DocumentId
        tags = $Tags
    }
    
    # Send the request
    "[log] Uploading $FilePath to $url"
    $Results = Invoke-RestMethod -Uri $url -Method Post -Form $form   -ContentType "multipart/form-data" -TransferEncoding chunked
    $Results
}

# Search through the uploaded documents with a query/prompt
function Search-Kernel($Query) {
    
    $URL = "http://127.0.0.1:9001/ask"
    
    $Query = @{
        question = $Query
    }|ConvertTo-Json # -Depth 5
    
    $Results = Invoke-WebRequest -Uri $URL -Method POST -Body $Query -ContentType "application/json"|ConvertFrom-Json
    Write-Host $Results.text -ForegroundColor Yellow
    
    
    ##################
    Write-Host "Sources:" $Results.relevantSources.sourceName -Separator "`n" -ForegroundColor Cyan
}

# Checkup on the status of the file upload using the DocumentID property
function Status-KernelFileUpload($documentId) {
    $url = "http://localhost:9001/upload-status?index=&documentId=$DocumentId"
    $Results = Invoke-RestMethod -Uri $url
    "`n[Uploading Document:$DocumentId]"
    "Upload Completed: " + $Results.completed
    "Completed Steps: " + $Results.completed_steps
    "Remaining Steps: " + $Results.remaining_steps
}

# Start the kernel-memory container using 'appsettings.Development.json'. (This file has the OpenAPI key!)
Start-KernelContainer

# Upload some files to search through, see here for valid file types: 
# https://github.com/microsoft/kernel-memory?tab=readme-ov-file#kernel-memory-km-and-semantic-memory-sm
Upload-KernelMemoryDocument -FilePath "C:\Scripts\KernelMemory\Tesla - Wikipedia.html"  
Upload-KernelMemoryDocument -FilePath "C:\Scripts\KernelMemory\France - Wikipedia.html"  

# Check if file is uploaded completely, fill in the DocumentID as returned by Upload-KernelMemoryDocument
Status-KernelFileUpload -documentId ""

# Ask questions about your documents
Search-Kernel -Query "What can you tell me about the Model Y?"
Search-Kernel -Query "Who is the founder of Tesla?"
Search-Kernel -Query "What do France and Tesla have in common?"
Search-Kernel -Query "Tell me five facts about France!"
