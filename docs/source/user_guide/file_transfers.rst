.. _user-guide.file-transfers:

===============================================
Automating file transfers from the spectrometer
===============================================

.. attention:: 
    🏗 Work in Progress 🏗

This guide gives some guidance on how you can link the spectrometer computer to the server running RTMet.
It's up to you to decide how you want to do this, as it can be quite dependent on your specific
setup, local network security policies, etc.

It is assumed that the spectrometer computer is running Windows, and the RTMet server is running a
Linux distribution.

Changing the input strategy in workflow configuration
=====================================================

By default, :rose:conf:`rose-suite.conf[template variables]cfg__input_strategy` is set to *internal*,
which means that the workflow will look for .raw files in the :file:`raws/` subdirectory of the
:term:`workflow run directory`.

You can change this behavior by setting :rose:conf:`rose-suite.conf[template variables]cfg__input_strategy`
to *local*, and defining the :rose:conf:`rose-suite.conf[template variables]cfg__local_runs_dir`
config option to point to a general directory where the raw files are stored: for each :term:`workflow run`,
you should store .raw files in a subdirectory with the same name as the run.


Exemple configuration and filetree:

.. code-block:: bash

    ├── transfered_raw_files
    │   ├── 20240617_experiment
    │   │   ├── file1.raw
    │   │   ├── file2.raw
    │   ├── run_2
    │   │   ├── file1.raw
    │   │   ├── file2.raw




Approaches for synchronized file access
=======================================

.. Option 1: Shared Network Drive
.. ------------------------------
.. One approach is to configure a shared network drive that both the spectrometer and the server can
.. access. This allows files to be easily transferred from the spectrometer to the server.

.. 1. **Configure the network drive**:
..    - Ensure the network drive is accessible from both the spectrometer and the server.
..    - Set up appropriate permissions to allow read/write access.

.. 2. **Automate the transfer**:
..    - On the spectrometer, configure the software to save output files directly to the shared network drive.
..    - On the server, create a script that regularly checks the network drive for new files and processes them accordingly.

.. Option 2: FTP/SFTP Transfers
.. ----------------------------
.. Another approach is to use FTP (File Transfer Protocol) or SFTP (Secure File Transfer Protocol) to transfer files from the spectrometer to the server.

.. 1. **Set up an FTP/SFTP server**:
..    - Install and configure FTP/SFTP server software on the server running RTMet.
..    - Create user accounts and set up directories with appropriate permissions for file transfer.

.. 2. **Automate the transfer**:
..    - On the spectrometer, configure FTP/SFTP client software to automatically upload files to the server at regular intervals or upon creation.
..    - Ensure secure transfer settings are enabled if using SFTP to protect data integrity and confidentiality.

.. Option 3: HTTP/HTTPS Transfers
.. ------------------------------
.. You can also set up an HTTP/HTTPS endpoint on the server to receive files from the spectrometer.

.. 1. **Set up an HTTP/HTTPS server**:
..    - Configure a web server (e.g., Apache, Nginx) on the server running RTMet to accept file uploads.
..    - Implement server-side scripts (e.g., PHP, Python) to handle incoming files and save them to the appropriate directory.

.. 2. **Automate the transfer**:
..    - On the spectrometer, configure it to send HTTP/HTTPS POST requests with the file data to the server endpoint.
..    - Ensure secure transfer settings (e.g., HTTPS) are enabled to protect data integrity and confidentiality.
