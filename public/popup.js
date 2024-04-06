document.querySelector('.showLoginButton').addEventListener('click', function() 
    { document.querySelector('.popUp').classList.add('active');
});
document.querySelector('#closeButton').addEventListener('click', function()
    {document.querySelector('.popUp').classList.remove('active');
});
