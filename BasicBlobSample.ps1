###Connect-Azure#### 
<# 
.SYNOPSIS  
    Sets up the connection to an Azure subscription 
 
.DESCRIPTION 
    This runbook sets up a connection to an Azure subscription by placing the Azure 
    management certificate into the local machine store and setting the connection to the subscription. 
  
.EXAMPLE 
    Connect-Azure -AzureConnectionName "AzureConnectionName" -SubscriptionName "Visual Studio Ultimate with MSDN" -StorageAccountName "MyStorageAccountName"  
#>  
workflow Connect-Azure 
{ 
    Param 
    (    
        # Name of the Azure connection setting that was created in the Automation service. 
        [Parameter(Mandatory=$true)] 
        [String] 
        $AzureConnectionName, 
        
        # Name of the subscription that corresponds to the connection's subscription id
        [Parameter(Mandatory=$true)] 
        [String] 
        $SubscriptionName,
        
        # Name of the storage account to use for storage operations
        [Parameter(Mandatory=$true)] 
        [String] 
        $StorageAccountName            
    ) 
     
    # Get the Azure connection asset that is stored in the Automation service based on the name that was passed into the runbook  
    $azureConn = Get-AutomationConnection -Name $AzureConnectionName 

    if ($azureConn -eq $null) 
    { 
        throw "Could not retrieve '$AzureConnectionName' connection asset. Check that you created this first in the Automation service." 
    } 
 
    # Get the Azure management certificate that is used to connect to this subscription 
    $Certificate = Get-AutomationCertificate -Name $azureConn.AutomationCertificateName 
    if ($Certificate -eq $null) 
    { 
        throw "Could not retrieve '$azureConn.AutomationCertificateName' certificate asset. Check that you created this first in the Automation service." 
    } 
   
    # Set the Azure subscription configuration 
    Select-AzureSubscription -SubscriptionName $SubscriptionName
    Set-AzureSubscription -SubscriptionName $SubscriptionName -SubscriptionId $azureConn.SubscriptionID -Certificate $Certificate -CurrentStorageAccountName $StorageAccountName
}

###Get-BlobSample#### 
<# 
.SYNOPSIS  
    Uploads a file to a blob then redownloads it
 
.DESCRIPTION 
    This runbook sets up a connection to an Azure subscription and storage account using Connect-Azure.
    Then it creates a local file, creates a blob container, and uploads that file into the container as a blob.
    Last it downloads the file and writes the file contents as output.
 
.EXAMPLE 
    Get-BlobSample -AzureConnectionName "AzureConnectionName" -SubscriptionName "Visual Studio Ultimate with MSDN" -StorageAccountName "MyStorageAccountName"  
#> 
workflow Get-BlobSample
{
    Param 
    (    
        # Name of the Azure connection setting that was created in the Automation service. 
        [Parameter(Mandatory=$true)] 
        [String] 
        $AzureConnectionName, 
        
        # Name of the subscription that corresponds to the connection's subscription id
        [Parameter(Mandatory=$true)] 
        [String] 
        $SubscriptionName,
        
        # Name of the storage account to use for storage operations
        [Parameter(Mandatory=$true)] 
        [String] 
        $StorageAccountName               
    ) 
        
    # Connect to the subscription using the Azure Connection and set the storage account to use
    Connect-Azure -AzureConnectionName $AzureConnectionName -SubscriptionName $SubscriptionName -StorageAccountName $StorageAccountName
    
    # Create a local file to upload
    $myFileContents = "File contents"
    $fileName = "myfile.txt"
    New-Item -Path $fileName -Value $myFileContents -ItemType File -Force

    $containerName = "my-automation-container"
    
    # Create the container
    New-AzureStorageContainer -Name $containerName
    
    # Upload the file contents
    Set-AzureStorageBlobContent -Container $containerName -File $fileName
        
    # Download the contents
    $downloadFileName = "DownloadedContent.txt"
    Get-AzureStorageBlobContent -Container $containerName -Blob $fileName -Destination $downloadFileName
    
    # Output the content
    $contents = Get-Item -Path $downloadFileName | Get-Content
    Write-Output $contents
}