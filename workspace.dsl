workspace "Patient monitoring and control (PMC) workspace" "This workspace documents the architecture of a generic Patient Monitoring and Control software"{

    model {
        //software systems
        pmac = softwareSystem "Patient Monitoring and Control (PMC)"{
            // containers
            webFrontend = container "PMC Web Front-end" "" "" "Web"
            pmcServer = container "PMC Server"{
                                
                group "Business Logic" {
                    patientDataAPI = component "Patient API" "provide API for alerting patients in emergency and getting patients lists in user's department, patients details and precscription records"
                    barcodeProcessor = component "Prescription Barcode Processor" "Process information scanned from the prescription barcode"
                }
                group "Domain Model" {
                    vitalSigns = component "Vital Signs Monitoring" "moniter patients vital signs and report in case of emergency"
                    patientsList = component "Patients List and Detail Storage" "provide list of patients or provide details of a patient"
                    detailRetrieval = component "Patient Detail Storage" "provide details of one patient"
                    prescriptionRecord = component "Precription Record Storage" "filter and store the list of patients who hasn't taken their precscription"
                    patientSpecific = component "Department Patients Data Storage"
                }
                group "Infrastructure" {
                    dataReader = component "Data Reader" "provide access to patients data"
                    dataWriter = component "Prescription Data Writer" "write prescription information from barcode scanner to db"
                }
            }
            !docs docs
        }

        //barcode scanner has more software to unpack the contents of the barcode
        //process this then send it to the server so it can be written to the db
        barCode = softwareSystem "Barcode scanner" "Existing System"

        prtds = softwareSystem "Patients Real Time Data System" "Contains data concerning the patient in real time" "Existing System"
        rop = softwareSystem "Registry of Patients" "Contains list of currently hospitalized patients" "Existing System"


        // persons
        doctors = person "Doctor" "A person (employee) from the Hospital who provides care to patients" "Doc"
        patients = person "Patient" "A person who is hopitalized and is equipped with monitoring devices" "Pat"

        // write prescription to database
        doctors -> barCode "Doctors use the barcode scanner to read the prescription data necessary"
        barcode -> barcodeProcessor "Send barcode to the processor where it will be unpacked" 
        barcodeProcessor -> dataWriter "Unpack prescription barcode information and send it to server to be written to db"
        dataWriter -> prtds "Send prescription information to db"
        # unpackBarcode -> dataWriter "Once the prescription is processed send it to the db "
        # dataWriter -> prtds "Write the prescription data to the db"
        # barcode -> scanner
        # scanner -> dataWriter "Read in prescription information"
        # dataWriter -> prtds "Write prescription information to db"
         
        // relationships between persons and systems
        doctors -> pmac "look up patients details in their departments as well as receive alerts about patients in emergency"
        patients -> prtds "input data(blood pressure, temperature, heartrate and inform break without-monitoring)"
        patients -> rop "sign up and sign off"

        // relationships between systems
        pmac -> prtds "read data from"
        rop -> prtds "inform patient lists change"

        // relationships between persons and containers
        doctors -> webFrontend "search and view patients details in; receive and view patients alerts in"

        // relationships between containers and systems
        pmcServer -> prtds "read from the data system"

        //relationships between containers 
        webFrontend -> pmcServer "use to deliver functionality"

        //relationships between containers and components
        webFrontend -> patientDataAPI "make API calls to"
        dataReader -> prtds "pull information from db"

        //relationships between components
        vitalSigns -> patientDataAPI "inform emergency of list of patients"
        vitalSigns -> patientSpecific "retrieve patient data from"
        vitalSigns -> patientsList "provide list of patients who are in emergency"

        patientDataAPI -> patientsList "retrieve patient list and detail of one patient if needed"

        patientsList -> detailRetrieval "inform to get details of one patient"
        patientsList -> patientSpecific "get list of patients from user's department"

        prescriptionRecord -> patientsList "provide list of patients who hasn't taken their precscription"
        prescriptionRecord -> patientSpecific "retrieve patient data from"

        detailRetrieval -> patientsList "provide details of one patient"
        detailRetrieval -> patientSpecific "retreive detail of one patient"

        patientSpecific -> dataReader "use to retrieve patients data from specific department"

        //deployment

        deploymentEnvironment "Deployment"  {
            deploymentNode "Patient's Portable Vital Signs Monitor Device" "" "MicroController"  {
                deploymentNode "Web Browser" "" "Chrome, Firefox or Edge"   {
                    containerInstance webFrontend
                }
            }
            deploymentNode "Doctor's Portable User Device" "" "Android"  {
                deploymentNode "Web Browser" "" "Chrome, Firefox or Edge"   {
                    containerInstance webFrontend
                }
            }
            deploymentNode "Doctor's Barcode Device" "" "Android"  {
                deploymentNode "Android Studio + SDK" {
                    softwareSystemInstance barCode
                }
            }
            deploymentNode "Virtual Server A" "" "Fedora" {
                deploymentNode "Node.js" "" "Node.js 14.*" {
                    containerInstance pmcServer
                }
            }
            deploymentNode "Virtual Server B" "" "Fedora" {
                    softwareSystemInstance prtds
                    softwareSystemInstance rop
            }
        }
    }

    views {
        systemlandscape "SystemLandscape_View" {
            include *
            autoLayout
        }

        systemContext barcode "Barcode_SystemContext_View"{
            include *
            autoLayout
        }

        systemContext pmac "PMC_SystemContext_View"{
            include *
            autoLayout
        }

        container pmac "PMC_Container_View"{
            include *
            autoLayout
        }

        component pmcServer "PMC_Server_Component_View"{
            include *
            autoLayout
        }

        systemContext prtds "PRTDS_SystemContext_View"{
            include *
            autoLayout
        }

        deployment pmac "Deployment" "PatientMonitoringandControlPMC_Live_Deployment" {
            include *
            autoLayout
        }

        dynamic * "Hospitalization_System_Dynamic_View" "Patient Monitoring and Control - Hospitalization Scenario"{
            patients -> rop  "register hospitalization"
            rop -> prtds "update patient list"
            //prtds -> pmac "inform to update"
            //dataReader -> webFrontend "update the cache"
            barCode -> pmac "prescribe medicine"
            pmac -> prtds "write prescription"
            autoLayout
        }

        dynamic pmcServer "Vitals_Signs_Component_Dynamic_View" "Patient Monitoring and Control - Vital Signs Monitory Scenario"{
            vitalSigns -> patientSpecific "inform to fetch latest data"
            patientSpecific -> dataReader "query and store the lastest data"
            dataReader -> prtds "fetch latest data"
            prtds -> dataReader "return latest data"
            dataReader -> patientSpecific "return the data for it to store"
            patientSpecific -> vitalSigns "return latest data"
            vitalSigns -> patientDataAPI "inform emergency if necessary"
            patientDataAPI -> webFrontend "inform emergency if necessary"
            autoLayout  
        }

        dynamic pmcServer "Doctor_Check_Component_Dynamic_View" "Patient Monitoring and Control - Doctor Check Scenario"{
            webFrontend -> patientDataAPI "check patients status"
            patientDataAPI -> webFrontend "return data"
            autoLayout
        }

        styles {
            element "Software System" {
                background #155B7A
                color #ffffff
            }
            
            element "Container" {
                background #208AB9
                color #ffffff
            }

            element "Component" {
                background #27A3DA
                color #ffffff
            }

            element "Existing System" {
                background #999999
                color #ffffff
            }

            element "Web"  {
                shape WebBrowser
            }

            element "Infrastructure"  {
                shape Pipe
            }

            element "Logic"  {
                shape Component
            }

            element "Model"  {
                shape RoundedBox
            }

            element "Person" {
                shape Person
            }

            element "Doc" {
                background #649EB8
                color #ffffff
            }

        }
    }   

}
