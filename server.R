library(shiny)
library(shinyRadioMatrix)


# Read the survey questions
Qlist <- read.csv("data/Qlist.csv")

# Read the radioMatrix rows and columns
RMF <- read.csv("data/RadioMatrixFrame.csv")


shinyServer(function(input, output) {
  
  # output$debug01 <- renderPrint({input$rmi01})
  
  # Create an empty vector to hold survey results
  results <<- rep("", nrow(Qlist))
  
  # Name each element of the vector based on the
  # second column of the Qlist
  names(results)  <<- Qlist[,2]
  
  # Hit counter
  output$counter <- 
    renderText({
      if (!file.exists("counter.Rdata")) counter <- 0
      if (file.exists("counter.Rdata")) load(file="counter.Rdata")
      counter <- counter <<- counter + 1
      
      save(counter, file="counter.Rdata")     
      paste0("Hits: ", counter)
    })
  
  # Hold the primary actions of the survey area
  output$MainAction <- renderUI( {
    dynamicUi()
  })
  
  # Dynamic UI interface changes as the survey progresses  
  dynamicUi <- reactive({
    
    # Initially show an introduction to survey 
    if (input$Click.Counter==0) 
      return(
        list(
          verticalLayout(
            
            strong(p(style="text-align: justify;",
                     "We maken het allemaal wel eens mee dat we zien dat iemand zich pijn doet,
                         verdrietig is of juist heel blij is. Als we zien dat iemand zich bijvoorbeeld snijdt,
                         het hoofd stoot of struikelt op straat dan weten we dat dat pijn doet maar voelen dat
                         soms ook. Als we horen dat iemand gepest is of buitengesloten wordt dan vinden we dat
                         vaak zielig en soms worden we van iemand die heel blij is zelf ook een beetje blij.
                         Het meeleven of meevoelen met de emoties van anderen doen we soms ongemerkt en met
                         de ene persoon meer dan met de ander. Wat wij graag van jou willen weten is wat jij
                         voelt en doet wanneer je ziet dat iemand verdrietig is, pijn heeft of juist blij is.",
                     style = "font-family: 'times'; font-si18pt")),
            strong(p(style="text-align: justify;",
                     "de volgende bladzijde staan een aantal uitspraken die gaan over het meevoelen met
                        anderen in verschillende situaties. Het kan natuurlijk zijn dat je nog nooit zo'n
                        situatie hebt meegemaakt. Probeer je dan voor te stellen hoe dat zou zijn,
                        wat je zou voelen en willen doen.",
                     style = "font-family: 'times'; font-si18pt"
            )),
            strong(p(style="text-align: justify;",
                     "Er zijn geen goede of foute antwoorden. Het gaat om jouw eigen gevoel.",
                     style = "font-family: 'times'; font-si18pt"
                     
            )),
            strong(p(style="text-align: justify;",
                     "Je antwoord geef je door het cijfer te omcirkelen wat het meest op jou van toepassing is:",
                     style = "font-family: 'times'; font-si18pt"
                     
            )),
            strong(p(style="text-align: justify;",
                     "1= helemaal niet van toepassing",
                     style = "font-family: 'times'; font-si18pt"
                     
            )),
            strong(p(style="text-align: justify;",
                     "2= een beetje van toepassing",
                     style = "font-family: 'times'; font-si18pt"
                     
            )),
            strong(p(style="text-align: justify;",
                     "3= redelijk goed van toepassing",
                     style = "font-family: 'times'; font-si18pt"
                     
            )),
            strong(p(style="text-align: justify;",
                     "4= sterk van toepassing",
                     style = "font-family: 'times'; font-si18pt"
                     
            )),
            strong(p(style="text-align: justify;",
                     "5= heel sterk van toepassing",
                     style = "font-family: 'times'; font-si18pt"
                     
            )
            ))
        )
      )
    # End Introduction
    
    # Update survey questions by clicking on Next-button
    if (input$Click.Counter>0 & input$Click.Counter<=nrow(Qlist))  
      return(
        list(
          strong(textOutput("question")),
          radioMatrixInput(inputId = "rmi01", rowIDs = RMF$rowID,
                           rowLLabels = RMF[,input$Click.Counter+1],
                           choices = RMF$columnNames
          ),
          
          strong("Stel dat het een meisje is die je verder niet kent. Wat voel je en doe je dan?"),
          radioMatrixInput(inputId = "rmi02", rowIDs = RMF$rowID,
                           rowLLabels = RMF[,input$Click.Counter+1],
                           choices = RMF$columnNames
          ),
          strong("Of een meisje die je niet graag mag. Wat voel je en doe je dan?"),
          radioMatrixInput(inputId = "rmi03", rowIDs = RMF$rowID,
                           rowLLabels = RMF[,input$Click.Counter+1],
                           choices = RMF$columnNames
          )
          
        )
      )
    
    # Finally we see results of the survey as well as a
    # download button.
    if (input$Click.Counter>nrow(Qlist))
      return(
        list(
          h4("View aggregate results"),
          tableOutput("surveyresults"),
          h4("Thanks for taking the survey!"),
          downloadButton('downloadData', 'Download Individual Results'),
          br(),
          h6("Haven't figured out how to get rid of 'next' button yet")
        )
      )    
  })
  
  # This reactive function is concerned primarily with
  # saving the results of the survey for this individual.
  output$save.results <- renderText({
    # After each click, save the results of the radio buttons.
    if ((input$Click.Counter>0)&(input$Click.Counter>!nrow(Qlist)))
      try(results[input$Click.Counter] <<- input$survey)
    # Try is used because of a brief moment in which
    # the if condition is true but input$survey = NULL
    
    # If the user has clicked through all of the survey questions
    # then R saves the results to the survey file
    if (input$Click.Counter==nrow(Qlist)+1) {
      if (file.exists("survey.results.Rdata")) 
        load(file="survey.results.Rdata")
      if (!file.exists("survey.results.Rdata")) 
        presults<-NULL
      presults <- presults <<- rbind(presults, results)
      rownames(presults) <- rownames(presults) <<- 
        paste("User", 1:nrow(presults))
      save(presults, file="survey.results.Rdata")
    }
    # There has to be a UI object to call this
    # function. therefore, render text that displays the content
    # of this function is set up
    ""
  })
  
  # Render the table of results from the survey
  output$surveyresults <- renderTable({
    t(summary(presults))
  })
  
  # Render the data downloader
  output$downloadData <- downloadHandler(
    filename = "IndividualData.csv",
    content = function(file) {
      write.csv(presults, file)
    }
  )
  
  # The option list is a reactive list of elements that
  # updates itself when the click counter is advanced
  option.list <- reactive({
    qlist <- Qlist[input$Click.Counter,3:ncol(Qlist)]
    # Remove items from the qlist if the option is empty
    # Convert the option list to matrix
    as.matrix(qlist[qlist!=""])
  })
  
  # Show the question number (Q:) followed by the question text
  output$question <- renderText({
    paste0(
      "V", input$Click.Counter,":", 
      Qlist[input$Click.Counter,2]
    )
  })
  
})